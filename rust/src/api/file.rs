// file manipulation
use std::{
    collections::HashMap,
    fs::{self, remove_dir_all, remove_file, File},
    io::{self, BufReader, Cursor, Read, Write},
    path::{Path, PathBuf},
};

use walkdir::WalkDir;
use zip::{write::FileOptions, ZipArchive, ZipWriter};

// Custom error
use crate::utils::{
    encryption::{VAULT_FILE, VERIFICATION_DATA},
    error::VaultError,
    utils::verify_and_get_decrypter,
};
// Encrytion
use crate::utils::encryption::{
    check_password, check_validation_data_exists, decrypt_data, encrypt_data, save_validation_data,
};
// Caching
use crate::utils::cache::cache_image;
// Utils
use crate::utils::utils::generate_unique_filename;
use crate::utils::utils::rename_with_parent;

use infer;

pub fn set_password(password: &str, dir: &str) -> Result<bool, VaultError> {
    Ok(check_password(password, dir)?)
}
pub fn save_password(password: &str, dir: &str) -> Result<(), VaultError> {
    Ok(save_validation_data(dir, password)?)
}
pub fn check_password_exist(dir: &str) -> bool {
    check_validation_data_exists(dir)
}
pub fn is_video(image_data: Vec<u8>) -> Result<bool, VaultError> {
    Ok(infer::is_video(&image_data))
}

pub fn create_dir(dir: String, album_name: String) -> Result<(), VaultError> {
    match fs::create_dir(dir.clone() + "/" + &album_name) {
        Ok(_) => Ok(()),
        Err(e) => {
            if e.kind() == io::ErrorKind::NotFound {
                fs::create_dir_all(dir.clone()).map_err(|e| VaultError::Error(e.to_string()))?;
                fs::create_dir(dir + "/" + &album_name)
                    .map_err(|e| VaultError::Error(e.to_string()))?;
                Ok(())
            } else {
                Err(VaultError::Error(e.to_string()))
            }
        }
    }
}

pub fn delete_dir(dir: &str) -> Result<(), VaultError> {
    match remove_dir_all(&dir) {
        Ok(_) => Ok(()),
        Err(e) => Err(VaultError::Error(e.to_string())),
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
                    }
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
    let smallest_entry = images.iter().min_by_key(|entry| entry.0.clone());

    match smallest_entry {
        Some((key, value)) => {
            let mut map = HashMap::new();
            map.insert(key.clone(), value.clone());
            Ok(Some(map))
        }
        None => Ok(None),
    }
}

pub fn get_file_thumb(path: &str) -> Result<Vec<u8>, VaultError> {
    let mut files_list = path
        .to_string()
        .split("/")
        .map(|s| s.to_string())
        .collect::<Vec<String>>();
    // let filename = files_list.pop().unwrap();
    match files_list.pop() {
        Some(filename) => {
            let path = files_list.join("/") + "/.thumbs/" + &filename;

            match File::open(path) {
                Ok(file) => {
                    let mut reader = BufReader::new(file);
                    let mut buffer = Vec::new();
                    match reader.read_to_end(&mut buffer) {
                        Ok(_) => Ok(decrypt_data(&buffer)?),
                        Err(e) => Err(VaultError::Error(e.to_string())),
                    }
                }
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        }
        None => Err(VaultError::Error("Invalid path".to_string())),
    }
}

pub fn get_file(path: &str) -> Result<Vec<u8>, VaultError> {
    match File::open(path) {
        Ok(file) => {
            let mut reader = BufReader::new(file);
            let mut buffer = Vec::new();
            match reader.read_to_end(&mut buffer) {
                Ok(_) => Ok(decrypt_data(&buffer)?),
                Err(e) => Err(VaultError::Error(e.to_string())),
            }
        }
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn save_media(image_data: Vec<u8>, dir: String) -> Result<(), VaultError> {
    let info = infer::get(&image_data);

    let category = match info {
        Some(t) if t.matcher_type() == infer::MatcherType::IMAGE => "image",
        Some(t) if t.matcher_type() == infer::MatcherType::VIDEO => "video",
        _ => "file",
    };

    let filename = generate_unique_filename(&dir, category);
    let path = Path::new(&dir).join(&filename);

    cache_image(
        &image_data,
        path.as_os_str().to_string_lossy().to_string(),
        2,
        2,
    )?;
    let encrypted_data = encrypt_data(&image_data)?;

    match File::create(&path) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => Ok(()),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn save_file(image_data: Vec<u8>, dir: String) -> Result<(), VaultError> {
    let path = Path::new(&dir).join(generate_unique_filename(&dir, "file"));
    let encrypted_data = encrypt_data(&image_data)?;

    match File::create(&path) {
        Ok(mut file) => match file.write_all(&encrypted_data) {
            Ok(_) => Ok(()),
            Err(e) => Err(VaultError::Error(e.to_string())),
        },
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn delete_file(path: &str) -> Result<(), VaultError> {
    let file_path = Path::new(path);
    let parent_folder = file_path.parent().unwrap();
    let file_name = file_path.file_name().unwrap();

    let mut thumbs_file = PathBuf::from(parent_folder);
    thumbs_file.push(".thumbs");
    thumbs_file.push(file_name);

    let mut hash_file = PathBuf::from(parent_folder);
    hash_file.push(".hash");
    hash_file.push(file_name);

    remove_file(path).map_err(|e| VaultError::Error(e.to_string()))?;

    if thumbs_file.exists() {
        remove_file(&thumbs_file).map_err(|e| VaultError::Error(e.to_string()))?;
    }

    if hash_file.exists() {
        remove_file(&hash_file).map_err(|e| VaultError::Error(e.to_string()))?;
    }

    Ok(())
}

pub fn move_file(source_file: &str, dest_dir: &str) -> Result<(), VaultError> {
    let source_path = Path::new(source_file);
    let source_name = source_path.file_name().unwrap();

    let dest_dir_path = Path::new(dest_dir);

    let mut dest_file = PathBuf::from(dest_dir_path);
    dest_file.push(source_name);

    let parent_folder = source_path.parent().unwrap();

    let mut thumbs_file = PathBuf::from(parent_folder);
    thumbs_file.push(".thumbs");
    thumbs_file.push(source_name);

    let mut dest_thumb_file = PathBuf::from(dest_dir_path);
    dest_thumb_file.push(".thumbs");
    dest_thumb_file.push(source_name);

    let mut hash_file = PathBuf::from(parent_folder);
    hash_file.push(".hash");
    hash_file.push(source_name);

    let mut dest_hash_file = PathBuf::from(dest_dir_path);
    dest_hash_file.push(".hash");
    dest_hash_file.push(source_name);

    rename_with_parent(source_path, dest_file.as_path())?;
    if thumbs_file.exists() {
        rename_with_parent(thumbs_file.as_path(), dest_thumb_file.as_path())?;
    }
    if hash_file.exists() {
        rename_with_parent(hash_file.as_path(), dest_hash_file.as_path())?;
    }

    Ok(())
}

pub fn zip_backup(root_dir: &str, save_path: &str, encryption: bool) -> Result<(), VaultError> {
    const SKIP_PATTERNS: &[&str] = &[".hash", ".thumbs"];

    let mut buffer = Cursor::new(Vec::new());
    let mut zip = ZipWriter::new(&mut buffer);
    let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);
    let src_path = Path::new(root_dir);

    for entry in WalkDir::new(src_path) {
        let entry = entry.unwrap();
        let path = entry.path();
        let name = path.strip_prefix(src_path).unwrap();

        // Skip .hash and .thumb folders and anything inside them
        if path.components().any(|component| {
            if let Some(component_str) = component.as_os_str().to_str() {
                SKIP_PATTERNS
                    .iter()
                    .any(|&pattern| component_str == pattern)
            } else {
                false
            }
        }) {
            continue;
        }

        if path.is_file() {
            zip.start_file(name.to_string_lossy(), options)
                .map_err(|e| VaultError::Error(e.to_string()))?;

            if encryption {
                match File::open(path.to_str().unwrap()) {
                    Ok(file) => {
                        let mut reader = BufReader::new(file);
                        let mut buffer = Vec::new();
                        match reader.read_to_end(&mut buffer) {
                            Ok(_) => zip
                                .write_all(&buffer)
                                .map_err(|e| VaultError::Error(format!("{:?}", e)))?,
                            Err(e) => return Err(VaultError::Error(e.to_string())),
                        }
                    }
                    Err(e) => return Err(VaultError::Error(e.to_string())),
                }
            } else {
                let decrypted_data = get_file(path.to_str().unwrap())?;
                zip.write_all(&decrypted_data)
                    .map_err(|e| VaultError::Error(format!("{:?}", e)))?;
            }
        } else if !name.as_os_str().is_empty() {
            zip.add_directory(name.to_string_lossy(), options)
                .map_err(|e| VaultError::Error(e.to_string()))?;
        }
    }

    drop(zip);

    match File::create(save_path) {
        Ok(mut file) => file
            .write_all(&buffer.into_inner())
            .map_err(|e| VaultError::Error(e.to_string())),
        Err(e) => Err(VaultError::Error(e.to_string())),
    }
}

pub fn restore_backup(
    root_dir: &str,
    zip_path: &str,
    password: Option<String>,
) -> Result<(), VaultError> {
    const SKIP_PATTERNS: &[&str] = &[".hash", ".thumbs", ".vault-key"];

    let zip = File::open(zip_path)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP file: {}", e)))?;
    let reader = BufReader::new(zip);
    let root_dir_path = Path::new(root_dir);

    let mut archive = ZipArchive::new(reader)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP archive: {}", e)))?;
    fs::create_dir_all(root_dir_path)
        .map_err(|e| VaultError::Error(format!("Failed to create target directory: {}", e)))?;

    // let decrypter = password.as_deref().map(PasswordDecrypter::new);
    let decrypter = if let Some(pass) = password {
        Some(verify_and_get_decrypter(&mut archive, &pass)?)
    } else {
        None
    };

    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| VaultError::Error(format!("Failed to access file in archive: {}", e)))?;

        let outpath = root_dir_path.join(file.name());

        // Skip files with .cache .hash .vault-key
        if SKIP_PATTERNS
            .iter()
            .any(|&pattern| file.name().contains(pattern))
        {
            continue;
        }

        if file.name().ends_with('/') {
            // Its a directory
            fs::create_dir_all(&outpath).map_err(|e| {
                VaultError::Error(format!(
                    "Failed to create directory {}: {}",
                    outpath.display(),
                    e
                ))
            })?;
        } else {
            // Its a file

            // Creating parent directory if its not exists
            if let Some(parent) = outpath.parent() {
                fs::create_dir_all(parent).map_err(|e| {
                    VaultError::Error(format!("Failed to create parent directory: {}", e))
                })?;
            }

            // Get file data
            let mut file_content = Vec::new();
            file.read_to_end(&mut file_content).map_err(|e| {
                VaultError::Error(format!("Failed to read file from archive: {}", e))
            })?;

            if let Some(ref decrypter) = decrypter {
                let decrypted_data = decrypter.decrypt(&file_content)?;
                if let Some(parent_dir) = outpath.parent() {
                    save_media(decrypted_data, parent_dir.to_string_lossy().to_string())?;
                }
            } else {
                if let Some(parent_dir) = outpath.parent() {
                    save_media(file_content, parent_dir.to_string_lossy().to_string())?;
                }
            }
        }
    }

    Ok(())
}

pub fn check_zip_password(zip_path: &str, password: &str) -> Result<bool, VaultError> {
    let zip = File::open(zip_path)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP file: {}", e)))?;
    let reader = BufReader::new(zip);
    let mut archive = ZipArchive::new(reader)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP archive: {}", e)))?;

    match verify_and_get_decrypter(&mut archive, password) {
        Ok(_) => Ok(true),
        Err(VaultError::IncorrectPassword) => Ok(false),
        Err(e) => Err(e),
    }
}

pub fn check_zip_encrypted(zip_path: &str) -> Result<bool, VaultError> {
    let zip = File::open(zip_path)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP file: {}", e)))?;
    let reader = BufReader::new(zip);
    let mut archive = ZipArchive::new(reader)
        .map_err(|e| VaultError::Error(format!("Failed to open ZIP archive: {}", e)))?;

    let mut file = match archive.by_name(VAULT_FILE) {
        Ok(file_in_zip) => file_in_zip,
        Err(_) => return Ok(false),
    };

    let mut content = Vec::new();
    file.read_to_end(&mut content)
        .map_err(|e| VaultError::Error(format!("Failed to read .vault-key content: {}", e)))?;

    Ok(content != VERIFICATION_DATA)
}
