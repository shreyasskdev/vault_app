use std::path::Path;

// Time
use chrono::Utc;

// filename
pub fn generate_unique_filename(base_dir: &str) -> String {
    let now = Utc::now();
    let date_time = now.format("%Y%m%d%H%M%S%9f").to_string();

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
