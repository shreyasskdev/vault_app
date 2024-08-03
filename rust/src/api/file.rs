// file manipulation
use std::{
    fs::{self, File},
    io::{self, BufReader, Read, Write},
    path::Path,
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

// Define an alias for the AES-256-CBC encryption mode
type Aes256Cbc = Cbc<Aes256, Pkcs7>;

// rand::thread_rng().gen::<[u8; 32]>().to_vec() // AES-256 key is 32 bytes
// rand::thread_rng().gen::<[u8; 16]>().to_vec() // AES block size is 16 bytes
// const KEY: [u8; 32] =  [109, 68, 173, 38, 172, 59, 15, 208, 246, 212, 249, 106, 148, 33, 131, 117, 29, 245, 146, 55, 196, 201, 10, 80, 107, 202, 84, 206, 53, 84, 2, 172];
// const IV: [u8; 16] = [90, 69, 71, 68, 176, 197, 72, 16, 102, 12, 175, 103, 39, 165, 16, 255];

const SALT_LEN: usize = 32;
const KEY_LEN: usize = 32;
const IV_LEN: usize = 16;

// let mut salt = [0u8; SALT_LEN];
// rng.fill(&mut salt);

const SALT: [u8; SALT_LEN] = [
    17, 128, 16, 104, 193, 198, 63, 155, 239, 14, 180, 237, 137, 144, 175, 49, 118, 108, 13, 147,
    174, 122, 195, 174, 176, 103, 104, 156, 151, 114, 101, 106,
];

pub enum VaultError {
    Error(String),
}

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
    match fs::create_dir(dir.clone() + "/Collectons/" + &album_name) {
        Ok(_) => Ok(()),
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                fs::create_dir_all(dir.clone() + "/Collectons/").unwrap();
                fs::create_dir(dir + "/Collectons/" + &album_name).unwrap();
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

pub fn get_images(dir: String) -> Result<Vec<String>, VaultError> {
    match fs::read_dir(dir) {
        Ok(entries) => {
            let mut files: Vec<String> = vec![];
            for entry in entries {
                let entry = entry.unwrap();
                if entry.path().is_file() {
                    files.push(entry.file_name().to_string_lossy().to_string());
                };
            }
            Ok(files)
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
