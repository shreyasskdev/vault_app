
// file manipulation
use std::{
    collections::HashMap, 
    fs::{
        self, 
        File
    }, 
    io::{
        self, 
        BufReader, 
        Cursor, 
        Read, 
        Write
    }, 
    path::Path,
};

// encryption
use aes::Aes256;
use block_modes::block_padding::Pkcs7;
use block_modes::{BlockMode, Cbc};

use chrono::Local;
// key generation
use pbkdf2::pbkdf2_hmac;
use sha2::Sha256;

// key memory safety
use lazy_static::lazy_static;
use std::sync::RwLock;
use zeroize::{Zeroize, ZeroizeOnDrop};

// Custom error
use crate::api::error::VaultError;

// Caching
use blurhash::encode;
use image::{imageops, EncodableLayout, GenericImageView};

// alias for the AES-256-CBC encryption mode
type Aes256Cbc = Cbc<Aes256, Pkcs7>;

const SALT_LEN: usize = 32;
const KEY_LEN: usize = 32;
const IV_LEN: usize = 16;


const SALT: [u8; SALT_LEN] = [
    17, 128, 16, 104, 193, 198, 63, 155, 239, 14, 180, 237, 137, 144, 175, 49, 118, 108, 13, 147,
    174, 122, 195, 174, 176, 103, 104, 156, 151, 114, 101, 106,
];



#[derive(Zeroize)]
struct CryptoParams {
    key: [u8; KEY_LEN],
    iv: [u8; IV_LEN],
}
impl ZeroizeOnDrop for CryptoParams {}
lazy_static! {
    static ref CRYPTO_PARAMS: RwLock<Option<CryptoParams>> = RwLock::new(None);
}

pub fn create_dir(dir: String, album_name: String) -> Result<(), VaultError> {
    match fs::create_dir(dir.clone() + "/" + &album_name) {
        Ok(_) => Ok(()),
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                fs::create_dir_all(dir.clone())
                    .map_err(|e| VaultError::Error(e.to_string()))?;
                fs::create_dir(dir + "/" + &album_name)
                    .map_err(|e| VaultError::Error(e.to_string()))?;
                Ok(())
            } else {
                Err(VaultError::Error(e.to_string()))
            }
        }
    }
}

pub fn get_dirs(dir: String) -> Result<Vec<String>, VaultError> {
    match fs::read_dir(dir.clone()) {
        Ok(entries) => {
            let mut directories: Vec<String> = vec![];
            for entry in entries {
                match entry {
                    Ok(entry) => {
                        if entry.path().is_dir() {
                            directories.push(entry.file_name().to_string_lossy().to_string());
                        };
                    },
                    Err(e) => return Err(VaultError::Error(e.to_string())),
                }
            }
            Ok(directories)
        }
        Err(_) => match fs::create_dir(dir) {
            Ok(_) => Ok(vec![]),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
    }
}

pub fn get_images(dir: String) -> Result<HashMap<String, (String, f32)>, VaultError> {
    match fs::read_dir(&dir) {
        Ok(entries) => {
            let mut files: HashMap<String, (String, f32)> = HashMap::new();
            for entry in entries {
                match entry {
                    Ok(entry) => {
                        if entry.path().is_file() {
                            let value = entry.file_name().to_string_lossy().to_string();
                            let file_path = Path::new(&dir).join(".hash").join(&value);
        
                            let buffer = fs::read(&file_path)
                                .map_err(|e| VaultError::Error(e.to_string()))?;
                            let contents = String::from_utf8(decrypt_data(&buffer)?)
                                .map_err(|e| VaultError::Error(e.to_string()))?
                                .split(" ")
                                .map(|s| s.to_string())
                                .collect::<Vec<String>>();

                            let aspect_ratio: f32 = contents[1].parse().unwrap();
                            let hash = contents[0].clone();

                            files.insert(value, (hash, aspect_ratio));
                            
                        };
                    }
                    Err(e) => return Err(VaultError::Error(e.to_string())),
                }
            }
            Ok(files)
        }
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn get_album_thumb(dir: &str) -> Result<Option<HashMap<String, (String, f32)>>, VaultError> {
    let images = get_images(dir.to_owned())?;
    let smallest_entry = images.iter()
        .min_by_key(|entry| entry.0.clone());

    match smallest_entry {
        Some((key, value)) => {
            let mut map = HashMap::new();
            map.insert(key.clone(), value.clone());
            Ok(Some(map))
        },
        None => Ok(None),
    }
}

pub fn get_file_thumb(path: &str) -> Result<Vec<u8>, VaultError> {
    let mut files_list = path.to_string().split("/").map(|s| s.to_string()).collect::<Vec<String>>();
    // let filename = files_list.pop().unwrap();
    match files_list.pop() {
        Some(filename) => {
            let path = files_list.join("/") + "/.thumbs/" + &filename;

            match File::open(path) {
                Ok(file) => {
                    let mut reader = BufReader::new(file);
                    let mut buffer = Vec::new();
                    match reader.read_to_end(&mut buffer) {
                        Ok(_) => {
                            Ok(decrypt_data(&buffer)?)
                        },
                        Err(e) => Err(VaultError::Error(e.to_string())),
                    }
                }
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        },
        None => Err(VaultError::Error("Invalid path".to_string())),
    }
}


pub fn get_file(path: &str) -> Result<Vec<u8>, VaultError> {
    match File::open(path) {
        Ok(file) => {
            let mut reader = BufReader::new(file);
            let mut buffer = Vec::new();
            match reader.read_to_end(&mut buffer) {
                Ok(_) => {
                    Ok(decrypt_data(&buffer)?)
                },
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        }
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn save_file(image_data: Vec<u8>, dir: String) -> Result<(), VaultError> {

    let path = Path::new(&dir).join(generate_unique_filename(&dir));

    cache_image(&image_data, path.as_os_str().to_string_lossy().to_string(), 2, 2)?;
    let encrypted_data = encrypt_data(&image_data)?;


    match File::create(&path) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => Ok(()),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

// ------ cryptography functions -------
fn encrypt_data(data: &[u8]) -> Result<Vec<u8>, VaultError> {
    match get_crypto_params()? {
        Some((key, iv)) => {
            match Aes256Cbc::new_from_slices(&key, &iv) {
                Ok(cipher) => {
                    Ok(cipher.encrypt_vec(data))
                },
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        },
        None => Err(VaultError::Error("Could not get key (empty or none)".to_string())),
    }
}

fn decrypt_data(encrypted_data: &[u8]) -> Result<Vec<u8>, VaultError> {
    match get_crypto_params()? {
        Some((key, iv)) => {
            match Aes256Cbc::new_from_slices(&key, &iv) {
                Ok(cipher) => {
                    match cipher.decrypt_vec(encrypted_data) {
                        Ok(decrypted_data) => Ok(decrypted_data),
                        Err(e) => Err(VaultError::Error(e.to_string())),
                    }
                },
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        },
        None => Err(VaultError::Error("Could not get key (empty or none)".to_string())),
    }
}

fn derive_key_and_iv(password: &str, salt: &[u8]) -> ([u8; KEY_LEN], [u8; IV_LEN]) {
    let mut derived_key = [0u8; KEY_LEN + IV_LEN];
    pbkdf2_hmac::<Sha256>(password.as_bytes(), salt, 100_000, &mut derived_key);

    let mut key = [0u8; KEY_LEN];
    let mut iv = [0u8; IV_LEN];
    key.copy_from_slice(&derived_key[..KEY_LEN]);
    iv.copy_from_slice(&derived_key[KEY_LEN..]);

    (key, iv)
}

// #[flutter_rust_bridge::frb(sync)]
pub fn set_crypto_params(password: &str) -> Result<bool, VaultError> {
    match CRYPTO_PARAMS.write() {
        Ok(mut params) => {
            let (derived_key, derived_iv) = derive_key_and_iv(password, &SALT);
            *params = Some(CryptoParams {
                key: derived_key,
                iv: derived_iv,
            });
            Ok(true)
        }
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

fn get_crypto_params() -> Result<Option<([u8; KEY_LEN], [u8; IV_LEN])>, VaultError> {
    match CRYPTO_PARAMS.read() {
        Ok(cryptoparams_option) => {
            match cryptoparams_option.as_ref() {
                Some(cryptoparams) => Ok(Some((cryptoparams.key.clone(), cryptoparams.iv.clone()))),
                None => Ok(None),
            }
        },
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

// Image caching functions ----------------------------------------
fn cache_image(image_data: &Vec<u8>, file_path: String, components_x: u32, components_y: u32) -> Result<(), VaultError> {
    let img = image::load_from_memory(image_data)
        .map_err(|e| VaultError::Error(e.to_string()))?;
    let (width, height) = img.dimensions();


    // creating a blur hash
    match encode(components_x, components_y, width, height, img.to_rgba8().as_bytes()) {
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

// filename
fn generate_unique_filename(base_dir: &str) -> String {
    let now = Local::now();
    let date_time = now.format("%Y%m%d%H%M%S").to_string();
    
    let mut counter = 1;
    loop {
        let filename = format!("{}_{:04}.image", date_time, counter);
        let full_path = Path::new(base_dir).join(&filename);
        
        if !full_path.exists() {
            return filename;
        }
        
        counter += 1;
        if counter > 9999 {
            panic!("Too many files with the same timestamp");
        }
    }
}