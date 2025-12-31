use std::{
    fs::File,
    io::{BufReader, Read},
    path::Path,
};

// Time
use chrono::Utc;
use zip::ZipArchive;

use crate::utils::{
    encryption::{PasswordDecrypter, VAULT_FILE, VERIFICATION_DATA},
    error::VaultError,
};

// filename
pub fn generate_unique_filename(base_dir: &str, ext: &str) -> String {
    let now = Utc::now();
    let date_time = now.format("%Y%m%d%H%M%S%9f").to_string();

    let mut counter = 1;
    loop {
        let filename = format!("{}_{:04}.{}", date_time, counter, ext);
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

pub fn verify_and_get_decrypter(
    archive: &mut ZipArchive<BufReader<File>>,
    password: &str,
) -> Result<PasswordDecrypter, VaultError> {
    let mut vault_key_file = archive
        .by_name(VAULT_FILE)
        .map_err(|_| VaultError::IncorrectPassword)?;

    let mut encrypted_content = Vec::new();
    vault_key_file
        .read_to_end(&mut encrypted_content)
        .map_err(|e| VaultError::Error(format!("Failed to read .vault-key from ZIP: {}", e)))?;

    let decrypter = PasswordDecrypter::new(password);

    match decrypter.decrypt(&encrypted_content) {
        Ok(decrypted_contet) if decrypted_contet == VERIFICATION_DATA => Ok(decrypter),
        _ => Err(VaultError::IncorrectPassword),
    }
}
