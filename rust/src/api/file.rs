use std::{
    path::Path,
    fs::{self, File},
    io::{self, Read, BufReader, Write}
};

pub enum VaultError {
    // NotFound(String),
    Error(String)
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
            };
            Ok(directories)
        }
        Err(_) => {
            match fs::create_dir(dir) {
                Ok(_) => Ok(vec![]),
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_images(dir: String) -> Result<Vec<String>, VaultError> {
    match fs::read_dir(dir) {
        Ok(entries) => {
            let mut files: Vec<String> = vec![];
            for entry in entries {
                let entry = entry.unwrap();
                if entry.path().is_file() {
                    files.push(entry.file_name().to_string_lossy().to_string());
                };
            };
            Ok(files)
        }
        Err(e) => Err(VaultError::Error(e.to_string()))
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_file(path: &str) -> Result<Vec<u8>, VaultError> {
    match File::open(path) {
        Ok(file) => {
            let mut reader = BufReader::new(file);
            let mut buffer = Vec::new();
            match reader.read_to_end(&mut buffer){
                Ok(_) => Ok(buffer),
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        }
        Err(e) => Err(VaultError::Error(e.to_string()))
    }
}


pub fn save_file(image_data: Vec<u8>, file_path: String) -> Result<(), VaultError> {
    let path = Path::new(&file_path);
    
    match File::create(&path) {
        Ok(mut file) => {
            match file.write_all(&image_data) {
                Ok(_) => Ok(()),
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        },
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}