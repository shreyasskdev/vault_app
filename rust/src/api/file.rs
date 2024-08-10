// file manipulation
use std::{
    collections::HashMap, fs::{self, File}, io::{self, BufReader, Cursor, Read, Write}, os::unix::ffi::OsStrExt, path::Path,
};

// encryption
use aes::Aes256;
use block_modes::block_padding::Pkcs7;
use block_modes::{BlockMode, Cbc};

// key generation
use pbkdf2::pbkdf2_hmac;
use sha2::Sha256;

// key memory safety
use lazy_static::lazy_static;
use std::sync::RwLock;
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::api::error::VaultError;


use blurhash::encode;
use image::{imageops, EncodableLayout, GenericImageView};

// use crate::api::database::*;

// Define an alias for the AES-256-CBC encryption mode
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
                fs::create_dir_all(dir.clone()).unwrap();
                fs::create_dir(dir + "/" + &album_name).unwrap();
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
                let entry = entry.unwrap();
                if entry.path().is_dir() {
                    directories.push(entry.file_name().to_string_lossy().to_string());
                };
            }
            Ok(directories)
        }
        Err(_) => match fs::create_dir(dir) {
            Ok(_) => Ok(vec![]),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
    }
}

pub fn get_images(dir: String) -> Result<HashMap<String, String>, VaultError> {
    match fs::read_dir(&dir) {
        Ok(entries) => {
            let mut files: HashMap<String, String> = HashMap::new();
            // let db = sled::open(Path::new(&dir).join("hash").as_os_str()).unwrap();
            // let db = get_or_create_db()?;
            // set_db_path(Path::new(&dir).join("hash").to_string_lossy().to_string())?;

            for entry in entries {
                let entry = entry.unwrap();
                if entry.path().is_file() {
                    let value = entry.file_name().to_string_lossy().to_string();
                    let file_path = Path::new(&dir).join("hash").join(&value);

                    let contents = fs::read_to_string(file_path).unwrap();
                    files.insert(value, contents);
                    
                };
            }
            Ok(files)
        }
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn get_album_thumb(dir: &str) -> Result<Option<HashMap<String, String>>, VaultError> {
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
    get_album_thumb(Path::new(path).parent().unwrap().to_str().unwrap())?;

    let mut files_list = path.to_string().split("/").map(|s| s.to_string()).collect::<Vec<String>>();
    let filename = files_list.pop().unwrap();
    let path = files_list.join("/") + "/thumbs/" + &filename;

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

pub fn save_file(image_data: Vec<u8>, file_path: String) -> Result<(), VaultError> {
    cache_image(&image_data, file_path.clone(), 2, 2)?;
    let encrypted_data = encrypt_data(&image_data)?;

    let path = Path::new(&file_path);
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
    let img = image::load_from_memory(image_data).unwrap();
    let (width, height) = img.dimensions();


    // creating a blur hash
    match encode(components_x, components_y, width, height, img.to_rgba8().as_bytes()) {
        Ok(hash) => {
            let path_temp = Path::new(file_path.as_str());
            let parent_path = path_temp.parent().unwrap();
            let hash_path = parent_path.join("hash").join(path_temp.file_name().unwrap());
            let path = hash_path.as_os_str();
            
            let mut file =  File::create(&path).unwrap();
            file.write_all(&hash.as_bytes()).unwrap();

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
    ).unwrap();

    // getting filepath
    let working_dir = Path::new(&file_path)
        .parent()
        .unwrap();
    let filename = working_dir
        .join(format!("thumbs/{}", Path::new(&file_path).file_name().unwrap().to_str().unwrap()));

    // saving file
    let encrypted_data = encrypt_data(&buffer)?;
    match File::create(&filename) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => Ok(()),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                create_dir(working_dir.to_string_lossy().to_string(), "thumbs".to_string())?;
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
