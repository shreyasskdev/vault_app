use std::fs;

pub fn get_files(dir: String)  {
    let entries = fs::read_dir(dir).unwrap();

    for entry in entries {
        let entry = entry.unwrap();
        let filename = entry.file_name();
        println!("{}", filename.to_str().unwrap());
    }
}