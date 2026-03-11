use markitdown::MarkItDown;
use std::{env, fs};

fn main() {
    let path = env::args().nth(1).unwrap_or_else(|| {
        "../sources/SWE1002-6_Cloud Computing Project.pdf".to_string()
    });

    let output_path = env::args().nth(2).unwrap_or_else(|| {
        "../sources/output.md".to_string()
    });

    let md = MarkItDown::new();
    match md.convert(&path, None) {
        Some(result) => {
            match fs::write(&output_path, &result.text_content) {
                Ok(_) => println!("Successfully wrote markdown to {}", output_path),
                Err(e) => eprintln!("Error writing file: {}", e),
            }
        },
        None => eprintln!("Error converting PDF"),
    }
}
