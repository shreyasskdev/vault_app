// file manipulation
use std::{
    fs::{self, File},
    io::{self, Cursor, Write},
    path::Path,
};

// Caching
use blurhash;
use image::{imageops, EncodableLayout, GenericImageView};
use infer::is_video;

// Custom error
use crate::utils::error::VaultError;
// Encrytion
use crate::utils::encryption::encrypt_data;

#[cfg(not(target_os = "android"))]
use gstreamer as gst;
#[cfg(not(target_os = "android"))]
use gstreamer::prelude::*;
#[cfg(not(target_os = "android"))]
use gstreamer_app::{AppSink, AppSrc};
use std::error::Error;

#[cfg(target_os = "android")]
use crate::JAVA_VM;
#[cfg(target_os = "android")]
use jni::objects::{JByteArray, JObject, JValue};
#[cfg(target_os = "android")]
use jni::JNIEnv;
#[cfg(target_os = "android")]
use std::os::unix::io::RawFd;

#[cfg(not(target_os = "android"))]
pub fn get_thumbnail_from_memory_gst(video_data: &Vec<u8>) -> Result<Vec<u8>, Box<dyn Error>> {
    // 1. Initialize GStreamer
    gst::init()?;

    // 2. Define the pipeline
    // appsrc -> decodebin -> videoconvert -> appsink
    // let pipeline_str = "appsrc name=src ! decodebin ! videoconvert ! video/x-raw,format=RGB ! appsink name=sink max-buffers=1 drop=true";
    let pipeline_str = "appsrc name=src ! decodebin ! videoconvert ! pngenc ! appsink name=sink max-buffers=1 drop=true";
    let pipeline = gst::parse::launch(pipeline_str)?
        .dynamic_cast::<gst::Pipeline>()
        .map_err(|_| "Failed to cast to Pipeline")?;

    let src = pipeline
        .by_name("src")
        .unwrap()
        .dynamic_cast::<AppSrc>()
        .unwrap();
    let sink = pipeline
        .by_name("sink")
        .unwrap()
        .dynamic_cast::<AppSink>()
        .unwrap();

    // 3. Set to Playing state
    pipeline.set_state(gst::State::Playing)?;

    // 4. Push the buffer into appsrc
    let buffer = gst::Buffer::from_slice(video_data.to_owned());
    src.push_buffer(buffer)?;
    src.end_of_stream()?; // Tell the pipeline no more data is coming

    // 5. Pull the frame from appsink
    let sample = sink
        .pull_sample()
        .map_err(|_| "Failed to pull sample (is the video valid?)")?;
    let buffer = sample.buffer().ok_or("Failed to get buffer from sample")?;

    // 6. Map the buffer to access raw bytes
    let map = buffer.map_readable()?;
    let data = map.as_slice().to_vec();

    // Cleanup
    pipeline.set_state(gst::State::Null)?;

    Ok(data)
}

fn create_fallback_image() -> image::DynamicImage {
    let grey_pixel = image::Rgb([128, 128, 128]);
    let filler_buffer = image::RgbImage::from_pixel(200, 200, grey_pixel);
    image::DynamicImage::ImageRgb8(filler_buffer)
}

// Image caching functions ----------------------------------------
pub fn cache_image(
    image_data: &Vec<u8>,
    file_path: String,
    components_x: u32,
    components_y: u32,
) -> Result<(), VaultError> {
    let img: image::DynamicImage = if is_video(image_data) {
        // Video
        #[cfg(not(target_os = "android"))]
        {
            match get_thumbnail_from_memory_gst(image_data) {
                Ok(raw_rgb_data) => image::load_from_memory(&raw_rgb_data)
                    .unwrap_or_else(|_| create_fallback_image()),
                Err(_) => create_fallback_image(),
            }
        }

        #[cfg(target_os = "android")]
        {
            // 1. Get the environment internally
            match get_jni_env() {
                Ok(mut env_guard) => {
                    // 2. Pass the guard (which acts as &mut JNIEnv) to your function
                    match get_thumbnail_no_disk(&mut env_guard, image_data) {
                        // Ok(raw_rgb_data) => image::load_from_memory(&raw_rgb_data)
                        //     .unwrap_or_else(|_| create_fallback_image()),
                        Ok(raw_rgb_data) => image::load_from_memory(&raw_rgb_data)
                            .map_err(|e| VaultError::Error(e.to_string()))?,
                        Err(_) => create_fallback_image(),
                    }
                }
                Err(_) => create_fallback_image(),
            }
        }
    } else {
        image::load_from_memory(image_data).unwrap_or_else(|_| create_fallback_image())
    };
    let (width, height) = img.dimensions();

    // creating a blur hash
    match blurhash::encode(
        components_x,
        components_y,
        width,
        height,
        img.to_rgba8().as_bytes(),
    ) {
        Ok(hash) => {
            let path_temp = Path::new(file_path.as_str());
            // let parent_path = path_temp.parent().unwrap();
            match path_temp.parent() {
                Some(parent_path) => {
                    // let hash_path = parent_path.join("hash").join(path_temp.file_name().unwrap());
                    match path_temp.file_name() {
                        Some(filename) => {
                            let hash_path = parent_path.join(".hash").join(filename);
                            let path = hash_path.as_os_str();

                            let content = format!("{} {:.2}", hash, width as f32 / height as f32);

                            match File::create(&path) {
                                Ok(mut file) => {
                                    file.write_all(&encrypt_data(&content.as_bytes())?)
                                        .map_err(|e| VaultError::Error(e.to_string()))?;
                                }
                                Err(e) => {
                                    if e.kind() == io::ErrorKind::NotFound {
                                        fs::create_dir_all(parent_path.join(".hash"))
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                        let mut file = File::create(&path)
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                        file.write_all(&encrypt_data(&content.as_bytes())?)
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                    } else {
                                        return Err(VaultError::Error(e.to_string()));
                                    }
                                }
                            }
                        }
                        None => return Err(VaultError::Error("Invalid path".to_string())),
                    }
                }
                None => return Err(VaultError::Error("Invalid path".to_string())),
            }
        }
        Err(e) => return Err(VaultError::Error(e.to_string())),
    }

    // resizing the image
    let thumbnail = img
        .resize_to_fill(
            200,
            (200.0 * img.height() as f64 / img.width() as f64) as u32,
            imageops::FilterType::Triangle,
        )
        .to_rgb8();
    let mut buffer = Vec::new();
    image::write_buffer_with_format(
        &mut Cursor::new(&mut buffer),
        thumbnail.as_bytes(),
        thumbnail.width(),
        thumbnail.height(),
        image::ColorType::Rgb8,
        image::ImageFormat::Jpeg,
    )
    .map_err(|e| VaultError::Error(e.to_string()))?;

    // getting filepath
    // let working_dir = Path::new(&file_path)
    //     .parent()
    //     .unwrap();
    let working_dir;
    match Path::new(&file_path).parent() {
        Some(parent) => working_dir = parent,
        None => return Err(VaultError::Error("Invalid path".to_string())),
    }
    // let filename = working_dir
    //     .join(format!("thumbs/{}", Path::new(&file_path).file_name().unwrap().to_str().unwrap()));
    let filename;
    match Path::new(&file_path).file_name() {
        Some(filepath) => match filepath.to_str() {
            Some(filepath_str) => {
                filename = working_dir.join(format!(".thumbs/{}", filepath_str));
            }
            None => return Err(VaultError::Error("Invalid path".to_string())),
        },
        None => return Err(VaultError::Error("Invalid path".to_string())),
    }

    // saving file
    let encrypted_data = encrypt_data(&buffer)?;
    match File::create(&filename) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => Ok(()),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                // create_dir(working_dir.to_string_lossy().to_string(), "thumbs".to_string())?;
                fs::create_dir_all(working_dir.join(".thumbs"))
                    .map_err(|e| VaultError::Error(e.to_string()))?;
                match File::create(&filename) {
                    Ok(mut file) => match file.write_all(&encrypted_data) {
                        Ok(_) => Ok(()),
                        Err(e) => Err(VaultError::Error(e.to_string())),
                    },
                    Err(_) => Err(VaultError::Error(e.to_string())),
                }
            } else {
                Err(VaultError::Error(e.to_string()))
            }
        }
    }
}
#[cfg(target_os = "android")]
pub fn get_thumbnail_no_disk(
    env: &mut JNIEnv,
    video_data: &[u8],
) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let fd = create_mem_fd("vid_thumb", video_data)?;

    // DUPLICATE the FD here.
    // Java will own the 'dup_fd', Rust continues to own 'fd'.
    let dup_fd = unsafe { libc::dup(fd) };
    if dup_fd == -1 {
        unsafe { libc::close(fd) };
        return Err("Failed to dup FD".into());
    }

    // Pass the DUPLICATED FD to the JNI helper
    let j_fd = native_fd_to_java_fd(env, dup_fd)?;

    let retriever_class = env.find_class("android/media/MediaMetadataRetriever")?;
    let retriever = env.new_object(retriever_class, "()V", &[])?;

    // Use the long version of setDataSource for FileDescriptor
    env.call_method(
        &retriever,
        "setDataSource",
        "(Ljava/io/FileDescriptor;JJ)V",
        &[
            (&j_fd).into(),
            0i64.into(),
            (video_data.len() as i64).into(),
        ],
    )?;

    let bitmap = env
        .call_method(
            &retriever,
            "getFrameAtTime",
            "(JI)Landroid/graphics/Bitmap;",
            &[0i64.into(), 2.into()], // 2 = OPTION_CLOSEST_SYNC
        )?
        .l()?;

    let result_bytes = bitmap_to_png_bytes(env, &bitmap)?;

    env.call_method(&retriever, "release", "()V", &[])?;

    // Now it is safe to close our original FD because Java owns the 'dup_fd'
    unsafe { libc::close(fd) };

    Ok(result_bytes)
}

/// Creates a file in RAM and returns the File Descriptor
#[cfg(target_os = "android")]
fn create_mem_fd(name: &str, data: &[u8]) -> Result<RawFd, Box<dyn std::error::Error>> {
    let c_name = std::ffi::CString::new(name)?;
    unsafe {
        // MFD_CLOEXEC prevents the FD from leaking to child processes
        let fd = libc::memfd_create(c_name.as_ptr(), libc::MFD_CLOEXEC);
        if fd == -1 {
            return Err("Failed to create memfd".into());
        }
        // Write the rust memory to the RAM file
        let written = libc::write(fd, data.as_ptr() as *const libc::c_void, data.len());
        if written == -1 {
            libc::close(fd);
            return Err("Failed to write to memfd".into());
        }
        // Reset cursor to beginning for the Media player to read
        libc::lseek(fd, 0, libc::SEEK_SET);
        Ok(fd)
    }
}

#[cfg(target_os = "android")]
fn native_fd_to_java_fd<'a>(
    env: &mut JNIEnv<'a>,
    fd: RawFd,
) -> Result<JObject<'a>, jni::errors::Error> {
    let pfd_class = env.find_class("android/os/ParcelFileDescriptor")?;

    // adoptFd takes ownership of the passed FD.
    let pfd = env
        .call_static_method(
            pfd_class,
            "adoptFd",
            "(I)Landroid/os/ParcelFileDescriptor;",
            &[JValue::Int(fd)],
        )?
        .l()?;

    let fd_obj = env
        .call_method(&pfd, "getFileDescriptor", "()Ljava/io/FileDescriptor;", &[])?
        .l()?;
    Ok(fd_obj)
}

#[cfg(target_os = "android")]
fn bitmap_to_png_bytes(env: &mut JNIEnv, bitmap: &JObject) -> Result<Vec<u8>, jni::errors::Error> {
    let baos_class = env.find_class("java/io/ByteArrayOutputStream")?;
    let baos = env.new_object(baos_class, "()V", &[])?;

    let compress_format_class = env.find_class("android/graphics/Bitmap$CompressFormat")?;
    let png_format = env
        .get_static_field(
            compress_format_class,
            "PNG",
            "Landroid/graphics/Bitmap$CompressFormat;",
        )?
        .l()?;

    env.call_method(
        bitmap,
        "compress",
        "(Landroid/graphics/Bitmap$CompressFormat;ILjava/io/OutputStream;)Z",
        &[
            JValue::Object(&png_format),
            JValue::Int(100),
            JValue::Object(&baos),
        ],
    )?;

    let byte_array_obj = env.call_method(&baos, "toByteArray", "()[B", &[])?.l()?;

    // Use this logic for jni 0.21:
    let byte_array = jni::objects::JByteArray::from(byte_array_obj);
    let vec: Vec<u8> = env.convert_byte_array(&byte_array)?;

    Ok(vec)
}

#[cfg(target_os = "android")]
fn get_jni_env() -> Result<jni::AttachGuard<'static>, Box<dyn std::error::Error>> {
    let vm = JAVA_VM
        .get()
        .ok_or("JavaVM not initialized. JNI_OnLoad was never called.")?;
    // Attach the current thread to the JVM
    let env = vm.attach_current_thread()?;
    Ok(env)
}
