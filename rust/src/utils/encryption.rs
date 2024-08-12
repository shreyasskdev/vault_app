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

// Custom error
use crate::utils::error::VaultError;

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


// ------ cryptography functions -------
pub fn encrypt_data(data: &[u8]) -> Result<Vec<u8>, VaultError> {
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

pub fn decrypt_data(encrypted_data: &[u8]) -> Result<Vec<u8>, VaultError> {
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
