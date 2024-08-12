// file manipulation
use std::{
    fs::{
        self, 
        File
    }, 
    io::{
        self, 
        Cursor,  
        Write
    }, 
    path::Path,
};

// Caching
use blurhash;
use image::{imageops, EncodableLayout, GenericImageView};

// Custom error
use crate::utils::error::VaultError;
// Encrytion
use crate::utils::encryption::encrypt_data;

// Image caching functions ----------------------------------------
pub fn cache_image(image_data: &Vec<u8>, file_path: String, components_x: u32, components_y: u32) -> Result<(), VaultError> {
    let img = image::load_from_memory(image_data)
        .map_err(|e| VaultError::Error(e.to_string()))?;
    let (width, height) = img.dimensions();


    // creating a blur hash
    match blurhash::encode(components_x, components_y, width, height, img.to_rgba8().as_bytes()) {
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
                                },
                                Err(e) => {
                                    if e.kind() == io::ErrorKind::NotFound {
                                        fs::create_dir_all(parent_path.join(".hash"))
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                        let mut file  = File::create(&path)
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                        file.write_all(&encrypt_data(&content.as_bytes())?)
                                            .map_err(|e| VaultError::Error(e.to_string()))?;
                                    } else {
                                        return Err(VaultError::Error(e.to_string()));
                                    }
                                },
                            }
                        },
                        None => return Err(VaultError::Error("Invalid path".to_string())),
                    }
                    
                },
                None => return Err(VaultError::Error("Invalid path".to_string())),
            }
            

        },
        Err(e) => return Err(VaultError::Error(e.to_string())),
    }

    // resizing the image
    let thumbnail = img.resize_to_fill(200, 200, imageops::FilterType::Triangle).to_rgb8();
    let mut buffer = Vec::new();
    image::write_buffer_with_format(
        &mut Cursor::new(&mut buffer),
        thumbnail.as_bytes(),
        thumbnail.width(),
        thumbnail.height(),
        image::ColorType::Rgb8,
        image::ImageFormat::Jpeg,
    ).map_err(|e| VaultError::Error(e.to_string()))?;

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
            },
            None => return Err(VaultError::Error("Invalid path".to_string())),
        },
        None => return Err(VaultError::Error("Invalid path".to_string())),
    }

    // saving file
    let encrypted_data = encrypt_data(&buffer)?;
    match File::create(&filename) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => {
                Ok(())
            },
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
                    }
                    Err(_) => Err(VaultError::Error(e.to_string())),
                }
            } else {
                Err(VaultError::Error(e.to_string()))
            }
        },
    }
}