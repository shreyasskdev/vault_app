#[cfg(test)]
mod tests {
    use super::super::file;
    use crate::utils::encryption::{decrypt_data, encrypt_data};
    use crate::utils::error::VaultError;
    use lazy_static::lazy_static;
    use rand::Rng;
    use std::{
        fs::{self},
        io::{BufRead, BufReader, Write},
        path::Path,
        sync::{Mutex, Once},
        time::{Instant, SystemTime, UNIX_EPOCH},
    };

    lazy_static! {
        static ref TEST_SUITE_START_TIME: u64 = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        static ref RUN_ID: String = format!(
            "{}-{}",
            *TEST_SUITE_START_TIME,
            rand::thread_rng().gen::<u64>()
        );
        static ref TEST_RESULTS_COLLECTOR: Mutex<Vec<(String, u128)>> = Mutex::new(Vec::new());
        static ref WRITE_ONCE: Once = Once::new();
    }

    // CSV file path (inside test folder)
    const CSV_LOG_FILE: &str = "test/test_timings.csv";

    // Base test directory
    const TEST_BASE_DIR: &str = "test";

    // Function to ensure CSV is written at the end of tests
    fn ensure_csv_written() {
        WRITE_ONCE.call_once(|| {
            write_results_to_csv();
        });
    }

    macro_rules! timed_test {
        ($test_name:expr, $test_logic:block) => {{
            let start_time = Instant::now();
            let result = std::panic::catch_unwind(|| $test_logic);
            let duration = start_time.elapsed();

            let mut results = TEST_RESULTS_COLLECTOR
                .lock()
                .unwrap_or_else(|e| e.into_inner());
            results.push(($test_name.trim().to_string(), duration.as_millis()));

            if result.is_err() {
                // Do not re-panic here. Let the test runner handle the failure.
                std::panic::resume_unwind(result.unwrap_err());
            }
        }};
    }

    // Function to write ALL collected results to CSV at once
    fn write_results_to_csv() {
        println!("Writing test results to CSV...");

        // Ensure test directory exists
        if let Err(e) = fs::create_dir_all(TEST_BASE_DIR) {
            println!("Error creating test directory: {}", e);
            return;
        }

        let mut results = TEST_RESULTS_COLLECTOR
            .lock()
            .unwrap_or_else(|e| e.into_inner());

        if results.is_empty() {
            println!("No results to write");
            return;
        }

        println!("Collected {} test results", results.len());

        // Get all unique test names in the order they first appeared
        let mut ordered_names = Vec::new();
        let mut timing_map = std::collections::HashMap::new();

        for (test_name, duration) in results.iter() {
            timing_map.insert(test_name.clone(), *duration);
            if !ordered_names.contains(test_name) {
                ordered_names.push(test_name.clone());
            }
        }

        let csv_path = Path::new(CSV_LOG_FILE);
        let file_exists = csv_path.exists();

        println!("CSV file exists: {}", file_exists);

        // Read existing headers and data if file exists
        let (existing_headers, existing_rows) = if file_exists {
            read_csv_file(csv_path)
        } else {
            (Vec::new(), Vec::new())
        };

        println!("Existing headers: {:?}", existing_headers);

        // Merge headers: keep existing order, add new test names at the end
        let mut final_headers = existing_headers.clone();
        for name in &ordered_names {
            if !final_headers.contains(name) {
                final_headers.push(name.clone());
            }
        }

        // If no existing headers, use the ordered names from this run
        if final_headers.is_empty() {
            final_headers = ordered_names.clone();
        }

        println!("Final headers: {:?}", final_headers);

        // Create the new row based on final headers
        let new_row: Vec<String> = final_headers
            .iter()
            .map(|header| {
                if let Some(duration) = timing_map.get(header) {
                    duration.to_string()
                } else {
                    String::new()
                }
            })
            .collect();

        println!("New row: {:?}", new_row);

        // Update existing rows to match new headers
        let updated_existing_rows: Vec<Vec<String>> = if file_exists && !existing_headers.is_empty()
        {
            existing_rows
                .iter()
                .map(|row| {
                    final_headers
                        .iter()
                        .map(|header| {
                            if let Some(pos) = existing_headers.iter().position(|h| h == header) {
                                if pos < row.len() {
                                    row[pos].clone()
                                } else {
                                    String::new()
                                }
                            } else {
                                String::new()
                            }
                        })
                        .collect()
                })
                .collect()
        } else {
            Vec::new()
        };

        // Write everything back to CSV
        match fs::File::create(csv_path) {
            Ok(mut file) => {
                // Write headers
                if let Err(e) = writeln!(file, "{}", final_headers.join(",")) {
                    println!("Error writing headers: {}", e);
                    return;
                }

                // Write existing rows (updated to match new headers)
                for row in updated_existing_rows {
                    if let Err(e) = writeln!(file, "{}", row.join(",")) {
                        println!("Error writing row: {}", e);
                        return;
                    }
                }

                // Write the new row
                if let Err(e) = writeln!(file, "{}", new_row.join(",")) {
                    println!("Error writing new row: {}", e);
                    return;
                }

                println!("Successfully wrote to CSV file: {}", csv_path.display());
            }
            Err(e) => {
                println!("Error creating CSV file: {}", e);
            }
        }

        // Clear the collector
        results.clear();
    }

    // Helper function to read existing CSV file
    fn read_csv_file(path: &Path) -> (Vec<String>, Vec<Vec<String>>) {
        let mut headers = Vec::new();
        let mut rows = Vec::new();

        match fs::File::open(path) {
            Ok(file) => {
                let reader = BufReader::new(file);
                for (i, line) in reader.lines().enumerate() {
                    match line {
                        Ok(row) => {
                            if i == 0 {
                                headers = row.split(',').map(|s| s.trim().to_string()).collect();
                            } else {
                                rows.push(row.split(',').map(|s| s.trim().to_string()).collect());
                            }
                        }
                        Err(e) => {
                            println!("Error reading line {}: {}", i, e);
                        }
                    }
                }
            }
            Err(e) => {
                println!("Error opening CSV file: {}", e);
            }
        }

        (headers, rows)
    }

    // Helper function to create a temporary directory for tests (inside test folder)
    fn setup_test_dir(dir_name: &str) -> String {
        let path = Path::new(TEST_BASE_DIR).join(dir_name);
        let path_str = path.to_str().unwrap().to_string();

        if path.exists() {
            fs::remove_dir_all(&path).unwrap();
        }
        fs::create_dir_all(&path).unwrap();

        // Set a default password for encryption to work in tests
        file::save_password("test_password_for_encryption", &path_str).unwrap();
        path_str
    }

    // Helper function to clean up a temporary directory
    fn teardown_test_dir(dir_name: &str) {
        let path = Path::new(dir_name);
        if path.exists() {
            fs::remove_dir_all(path).unwrap();
        }
    }

    // Helper to create a dummy encrypted file with hash and thumb
    fn create_dummy_vault_file(
        base_dir: &str,
        filename: &str,
        content: &[u8],
        hash: &str,
        aspect_ratio: f32,
        thumb_content: &[u8],
    ) {
        let file_path = Path::new(base_dir).join(filename);
        let hash_dir = Path::new(base_dir).join(".hash");
        let thumbs_dir = Path::new(base_dir).join(".thumbs");

        fs::create_dir_all(&hash_dir).unwrap();
        fs::create_dir_all(&thumbs_dir).unwrap();

        // Create main file
        let encrypted_content = encrypt_data(content).unwrap();
        fs::File::create(&file_path)
            .unwrap()
            .write_all(&encrypted_content)
            .unwrap();

        // Create hash file
        let hash_file_path = hash_dir.join(filename);
        let hash_data = format!("{} {}", hash, aspect_ratio);
        let encrypted_hash_data = encrypt_data(hash_data.as_bytes()).unwrap();
        fs::File::create(&hash_file_path)
            .unwrap()
            .write_all(&encrypted_hash_data)
            .unwrap();

        // Create thumbnail file
        let thumb_file_path = thumbs_dir.join(filename);
        let encrypted_thumb_content = encrypt_data(thumb_content).unwrap();
        fs::File::create(&thumb_file_path)
            .unwrap()
            .write_all(&encrypted_thumb_content)
            .unwrap();
    }

    // Cleanup function to remove all test directories after all tests
    fn cleanup_all_test_dirs() {
        let test_base = Path::new(TEST_BASE_DIR);
        if test_base.exists() {
            // Don't delete CSV file, just the test directories
            for entry in fs::read_dir(test_base).unwrap() {
                let entry = entry.unwrap();
                let path = entry.path();
                if let Some(name) = path.file_name() {
                    if name != "templates" && name != "test_timings.csv" {
                        if path.is_dir() {
                            let _ = fs::remove_dir_all(path);
                        } else {
                            let _ = fs::remove_file(path);
                        }
                    }
                }
            }
        }
    }

    // Test that writes CSV at the end - this should run last due to name ordering
    #[test]
    fn zzz_write_csv_results() {
        ensure_csv_written();
    }

    // Final cleanup test - runs after all tests
    // #[test]
    // fn zzzz_cleanup_test_dirs() {
    //     cleanup_all_test_dirs();
    // }

    #[test]
    fn test_create_dir() {
        timed_test!("test_create_dir", {
            let test_dir = setup_test_dir("test_create_dir_temp");
            let album_name = "my_test_album";
            let full_path = format!("{}/{}", test_dir, album_name);

            let result = file::create_dir(test_dir.clone(), album_name.to_string());
            assert!(result.is_ok());
            assert!(Path::new(&full_path).is_dir());

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_save_and_check_password() {
        timed_test!("test_save_and_check_password", {
            let test_dir = setup_test_dir("test_password_temp");
            let password = "test_password";

            let save_result = file::save_password(password, &test_dir);
            assert!(save_result.is_ok());

            let exists = file::check_password_exist(&test_dir);
            assert!(exists);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_set_password() {
        timed_test!("test_set_password", {
            let test_dir = setup_test_dir("test_set_password_temp");
            let password = "test_password_for_encryption";
            let wrong_password = "wrong_password";

            let result_correct = file::set_password(password, &test_dir);
            assert!(result_correct.is_ok());
            assert_eq!(result_correct.unwrap(), true);

            let result_wrong = file::set_password(wrong_password, &test_dir);
            assert!(result_wrong.is_err());
            match result_wrong.unwrap_err() {
                VaultError::IncorrectPassword => assert!(true),
                e => panic!("Expected IncorrectPassword error, but got {:?}", e),
            }

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_delete_dir() {
        timed_test!("test_delete_dir", {
            let test_dir = setup_test_dir("test_delete_dir_temp");
            let sub_dir = format!("{}/sub_dir", test_dir);
            fs::create_dir_all(&sub_dir).unwrap();

            assert!(Path::new(&sub_dir).is_dir());

            let delete_result = file::delete_dir(&test_dir);
            assert!(delete_result.is_ok());
            assert!(!Path::new(&test_dir).exists());
            assert!(!Path::new(&sub_dir).exists());

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_get_dirs() {
        timed_test!("test_get_dirs", {
            let test_dir = setup_test_dir("test_get_dirs_temp");
            let dir1 = format!("{}/dir1", test_dir);
            let dir2 = format!("{}/dir2", test_dir);
            let file1 = format!("{}/file1.txt", test_dir);

            fs::create_dir_all(&dir1).unwrap();
            fs::create_dir_all(&dir2).unwrap();
            fs::File::create(&file1).unwrap();

            let result = file::get_dirs(test_dir.clone());
            assert!(result.is_ok());
            let mut dirs = result.unwrap();
            dirs.sort();

            assert_eq!(dirs, vec!["dir1".to_string(), "dir2".to_string()]);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_is_video() {
        timed_test!("test_is_video", {
            let video_data = vec![
                0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34,
            ];
            let non_video_data = vec![0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

            let is_video_result = file::is_video(video_data);
            assert!(is_video_result.is_ok());
            assert!(!is_video_result.unwrap());

            let is_not_video_result = file::is_video(non_video_data);
            assert!(is_not_video_result.is_ok());
            assert!(!is_not_video_result.unwrap());
        });
    }

    #[test]
    fn test_save_and_get_file() {
        timed_test!("test_save_and_get_file", {
            let test_dir = setup_test_dir("test_save_get_file_temp");
            let original_data = b"This is some test file content.";

            let save_result = file::save_file(original_data.to_vec(), test_dir.clone());
            assert!(save_result.is_ok());

            let entries = fs::read_dir(&test_dir).unwrap();
            let saved_file_path = entries
                .filter_map(|e| e.ok())
                .map(|e| e.path())
                .find(|p| p.is_file() && !p.file_name().unwrap().to_str().unwrap().starts_with("."))
                .expect("No file found in test directory");

            let retrieved_data_result = file::get_file(saved_file_path.to_str().unwrap());
            assert!(retrieved_data_result.is_ok());
            let retrieved_data = retrieved_data_result.unwrap();

            assert_eq!(retrieved_data, original_data);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_save_media() {
        timed_test!("test_save_media", {
            let test_dir = setup_test_dir("test_save_media_temp");
            let media_data = b"This is some test media content.";
            let save_result = file::save_media(media_data.to_vec(), test_dir.clone());
            assert!(save_result.is_ok());

            let entries = fs::read_dir(&test_dir).unwrap();
            let saved_file_path = entries
                .filter_map(|e| e.ok())
                .map(|e| e.path())
                .find(|p| p.is_file() && !p.file_name().unwrap().to_str().unwrap().starts_with("."))
                .expect("No media file found in test directory");

            assert!(saved_file_path.exists());

            let encrypted_content = fs::read(&saved_file_path).unwrap();
            let decrypted_content = decrypt_data(&encrypted_content).unwrap();
            assert_eq!(decrypted_content, media_data);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_delete_file() {
        timed_test!("test_delete_file", {
            let test_dir = setup_test_dir("test_delete_file_temp");
            let filename = "test_image.jpg";
            let content = b"dummy image data";
            let hash = "somehash";
            let aspect_ratio = 1.5;
            let thumb_content = b"dummy thumb data";

            create_dummy_vault_file(
                &test_dir,
                filename,
                content,
                hash,
                aspect_ratio,
                thumb_content,
            );

            let file_path = Path::new(&test_dir).join(filename);
            let hash_file_path = Path::new(&test_dir).join(".hash").join(filename);
            let thumb_file_path = Path::new(&test_dir).join(".thumbs").join(filename);

            assert!(file_path.exists());
            assert!(hash_file_path.exists());
            assert!(thumb_file_path.exists());

            let delete_result = file::delete_file(file_path.to_str().unwrap());
            assert!(delete_result.is_ok());

            assert!(!file_path.exists());
            assert!(!hash_file_path.exists());
            assert!(!thumb_file_path.exists());

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_move_file() {
        timed_test!("test_move_file", {
            let src_dir = setup_test_dir("test_move_file_src");
            let dest_dir = setup_test_dir("test_move_file_dest");
            let filename = "test_move.png";
            let content = b"move me";
            let hash = "movehash";
            let aspect_ratio = 1.0;
            let thumb_content = b"move thumb";

            create_dummy_vault_file(
                &src_dir,
                filename,
                content,
                hash,
                aspect_ratio,
                thumb_content,
            );

            let src_file_path = Path::new(&src_dir).join(filename);
            let src_hash_file_path = Path::new(&src_dir).join(".hash").join(filename);
            let src_thumb_file_path = Path::new(&src_dir).join(".thumbs").join(filename);

            let dest_file_path = Path::new(&dest_dir).join(filename);
            let dest_hash_file_path = Path::new(&dest_dir).join(".hash").join(filename);
            let dest_thumb_file_path = Path::new(&dest_dir).join(".thumbs").join(filename);

            assert!(src_file_path.exists());
            assert!(src_hash_file_path.exists());
            assert!(src_thumb_file_path.exists());
            assert!(!dest_file_path.exists());
            assert!(!dest_hash_file_path.exists());
            assert!(!dest_thumb_file_path.exists());

            let move_result = file::move_file(src_file_path.to_str().unwrap(), &dest_dir);
            assert!(move_result.is_ok());

            assert!(!src_file_path.exists());
            assert!(!src_hash_file_path.exists());
            assert!(!src_thumb_file_path.exists());
            assert!(dest_file_path.exists());
            assert!(dest_hash_file_path.exists());
            assert!(dest_thumb_file_path.exists());

            teardown_test_dir(&src_dir);
            teardown_test_dir(&dest_dir);
        });
    }

    #[test]
    fn test_get_images() {
        timed_test!("test_get_images", {
            let test_dir = setup_test_dir("test_get_images_temp");
            let filename1 = "image1.jpg";
            let content1 = b"image data 1";
            let hash1 = "hash1";
            let aspect_ratio1 = 1.0;
            let thumb_content1 = b"thumb1";

            let filename2 = "image2.png";
            let content2 = b"image data 2";
            let hash2 = "hash2";
            let aspect_ratio2 = 1.5;
            let thumb_content2 = b"thumb2";

            create_dummy_vault_file(
                &test_dir,
                filename1,
                content1,
                hash1,
                aspect_ratio1,
                thumb_content1,
            );
            create_dummy_vault_file(
                &test_dir,
                filename2,
                content2,
                hash2,
                aspect_ratio2,
                thumb_content2,
            );

            let result = file::get_images(test_dir.clone());
            assert!(result.is_ok());
            let images = result.unwrap();

            assert_eq!(images.len(), 2);
            assert_eq!(images[filename1].0, hash1);
            assert_eq!(images[filename1].1, aspect_ratio1);
            assert_eq!(images[filename2].0, hash2);
            assert_eq!(images[filename2].1, aspect_ratio2);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_get_album_thumb() {
        timed_test!("test_get_album_thumb", {
            let test_dir = setup_test_dir("test_get_album_thumb_temp");
            let filename1 = "image_b.jpg";
            let content1 = b"image data b";
            let hash1 = "hash_b";
            let aspect_ratio1 = 1.0;
            let thumb_content1 = b"thumb_b";

            let filename2 = "image_a.png";
            let content2 = b"image data a";
            let hash2 = "hash_a";
            let aspect_ratio2 = 1.5;
            let thumb_content2 = b"thumb_a";

            create_dummy_vault_file(
                &test_dir,
                filename1,
                content1,
                hash1,
                aspect_ratio1,
                thumb_content1,
            );
            create_dummy_vault_file(
                &test_dir,
                filename2,
                content2,
                hash2,
                aspect_ratio2,
                thumb_content2,
            );

            let result = file::get_album_thumb(&test_dir);
            assert!(result.is_ok());
            let thumb_map = result.unwrap().expect("Should have a thumbnail");

            assert_eq!(thumb_map.len(), 1);
            assert!(thumb_map.contains_key(filename2));
            assert_eq!(thumb_map[filename2].0, hash2);
            assert_eq!(thumb_map[filename2].1, aspect_ratio2);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_get_file_thumb() {
        timed_test!("test_get_file_thumb", {
            let test_dir = setup_test_dir("test_get_file_thumb_temp");
            let filename = "test_file.jpg";
            let content = b"main file content";
            let hash = "filehash";
            let aspect_ratio = 1.0;
            let thumb_content = b"this is the thumbnail content";

            create_dummy_vault_file(
                &test_dir,
                filename,
                content,
                hash,
                aspect_ratio,
                thumb_content,
            );

            let file_path_for_thumb = Path::new(&test_dir).join(filename);
            let result = file::get_file_thumb(file_path_for_thumb.to_str().unwrap());
            assert!(result.is_ok());
            let retrieved_thumb = result.unwrap();

            assert_eq!(retrieved_thumb, thumb_content);

            teardown_test_dir(&test_dir);
        });
    }

    #[test]
    fn test_zip_backup_no_encryption() {
        timed_test!("test_zip_backup_no_encryption", {
            let src_dir = Path::new(TEST_BASE_DIR)
                .join("templates/Collections")
                .to_str()
                .unwrap()
                .to_string();
            let zip_path = Path::new(TEST_BASE_DIR).join("backup.zip");

            let pass = file::set_password("123", &src_dir);

            let result = file::zip_backup(&src_dir, zip_path.to_str().unwrap(), false);

            assert!(result.is_ok());
            assert!(pass.is_ok());
            assert!(zip_path.exists());
        });
    }

    #[test]
    fn test_zip_backup_with_encryption() {
        timed_test!("test_zip_backup_with_encryption", {
            let src_dir = Path::new(TEST_BASE_DIR)
                .join("templates/Collections")
                .to_str()
                .unwrap()
                .to_string();
            let zip_path = Path::new(TEST_BASE_DIR).join("encrypted_backup.zip");

            let result = file::zip_backup(&src_dir, zip_path.to_str().unwrap(), true);

            assert!(result.is_ok());
            assert!(zip_path.exists());
        });
    }

    #[test]
    fn test_restore_backup_no_encryption() {
        timed_test!("test_restore_backup_no_encryption", {
            let src_dir = setup_test_dir("test_restore_backup_src_no_enc");
            let dest_dir = setup_test_dir("test_restore_backup_dest_no_enc");
            let zip_path = Path::new(&src_dir).join("backup.zip");
            let filename = "test_file.txt";
            let content = b"This is a test file for restore.";
            let hash = "testhashrestore";
            let aspect_ratio = 1.0;
            let thumb_content = b"testthumbrestore";

            create_dummy_vault_file(
                &src_dir,
                filename,
                content,
                hash,
                aspect_ratio,
                thumb_content,
            );
            file::zip_backup(&src_dir, zip_path.to_str().unwrap(), false).unwrap();

            let result = file::restore_backup(&dest_dir, zip_path.to_str().unwrap(), None);
            assert!(result.is_ok());

            let restored_file_path = Path::new(&dest_dir).join(filename);
            assert!(restored_file_path.exists());
            let restored_content = file::get_file(restored_file_path.to_str().unwrap()).unwrap();
            assert_eq!(restored_content, content);

            teardown_test_dir(&src_dir);
            teardown_test_dir(&dest_dir);
        });
    }

    #[test]
    fn test_restore_backup_with_encryption() {
        timed_test!("test_restore_backup_with_encryption", {
            let src_dir = setup_test_dir("test_restore_backup_src_with_enc");
            let dest_dir = setup_test_dir("test_restore_backup_dest_with_enc");
            let zip_path = Path::new(&src_dir).join("encrypted_backup.zip");
            let filename = "test_file_enc.txt";
            let content = b"This is an encrypted test file for restore.";
            let hash = "testhashencrestore";
            let aspect_ratio = 1.0;
            let thumb_content = b"testthumbencrestore";
            let password = "restore_password";

            file::save_password(password, &src_dir).unwrap();
            create_dummy_vault_file(
                &src_dir,
                filename,
                content,
                hash,
                aspect_ratio,
                thumb_content,
            );
            file::zip_backup(&src_dir, zip_path.to_str().unwrap(), true).unwrap();

            let result = file::restore_backup(
                &dest_dir,
                zip_path.to_str().unwrap(),
                Some(password.to_string()),
            );
            assert!(result.is_ok());

            let restored_file_path = Path::new(&dest_dir).join(filename);
            assert!(restored_file_path.exists());
            let restored_content = file::get_file(restored_file_path.to_str().unwrap()).unwrap();
            assert_eq!(restored_content, content);

            teardown_test_dir(&src_dir);
            teardown_test_dir(&dest_dir);
        });
    }

    #[test]
    fn test_check_zip_password_correct() {
        timed_test!("test_check_zip_password_correct", {
            let src_dir = setup_test_dir("test_check_zip_password_correct_src");
            let zip_path = Path::new(&src_dir).join("encrypted.zip");
            let password = "correct_password";

            file::save_password(password, &src_dir).unwrap();
            file::zip_backup(&src_dir, zip_path.to_str().unwrap(), true).unwrap();

            let result = file::check_zip_password(zip_path.to_str().unwrap(), password);
            assert!(result.is_ok());
            assert!(result.unwrap());

            teardown_test_dir(&src_dir);
        });
    }

    #[test]
    fn test_check_zip_password_incorrect() {
        timed_test!("test_check_zip_password_incorrect", {
            let src_dir = setup_test_dir("test_check_zip_password_incorrect_src");
            let zip_path = Path::new(&src_dir).join("encrypted.zip");
            let correct_password = "correct_password";
            let wrong_password = "wrong_password";

            file::save_password(correct_password, &src_dir).unwrap();
            file::zip_backup(&src_dir, zip_path.to_str().unwrap(), true).unwrap();

            let result = file::check_zip_password(zip_path.to_str().unwrap(), wrong_password);
            assert!(result.is_ok());
            assert!(!result.unwrap());

            teardown_test_dir(&src_dir);
        });
    }

    #[test]
    fn test_check_zip_encrypted() {
        timed_test!("test_check_zip_encrypted", {
            let src_dir_enc = setup_test_dir("test_check_zip_encrypted_enc_src");
            let zip_path_enc = Path::new(&src_dir_enc).join("encrypted.zip");
            file::save_password("any_password", &src_dir_enc).unwrap();
            file::zip_backup(&src_dir_enc, zip_path_enc.to_str().unwrap(), true).unwrap();

            let src_dir_no_enc = setup_test_dir("test_check_zip_encrypted_no_enc_src");
            let zip_path_no_enc = Path::new(&src_dir_no_enc).join("not_encrypted.zip");
            file::zip_backup(&src_dir_no_enc, zip_path_no_enc.to_str().unwrap(), false).unwrap();

            let result_enc = file::check_zip_encrypted(zip_path_enc.to_str().unwrap());
            assert!(result_enc.is_ok());
            assert!(result_enc.unwrap());

            let result_no_enc = file::check_zip_encrypted(zip_path_no_enc.to_str().unwrap());
            assert!(result_no_enc.is_ok());
            assert!(!result_no_enc.unwrap());

            teardown_test_dir(&src_dir_enc);
            teardown_test_dir(&src_dir_no_enc);
        });
    }
}
