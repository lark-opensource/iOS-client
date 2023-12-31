use crate::cmd::run_command;
use crate::filesize::FileSize;
use crate::filesize::FileSize::*;
use cmd_lib::run_cmd;
use colored::*;
use dirs;
use dirs::home_dir;
use std::cmp::Ordering;
use std::cmp::Ordering::{Equal, Greater, Less};
use std::error::Error;
use std::fs;
use std::fs::File;
use std::io;
use std::path;
use std::path::{Path, PathBuf};
use walkdir::{DirEntry, WalkDir};

const APPENDED_POD_CACHE_PATH: &str = "/Library/Caches/CocoaPods/1.11.2/Pods/Release";

fn get_size(path: &PathBuf) -> FileSize {
    let newPath = Path::new(path.to_str().unwrap());
    let total_size = WalkDir::new(newPath)
        .min_depth(1)
        .max_depth(100)
        .into_iter()
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| entry.metadata().ok())
        .filter(|metadata| metadata.is_file())
        .fold(0, |acc, m| acc + m.len());
    return FileSize::B(total_size as f64);
}

fn get_outdated_pods(path: &Path, outdated_days: i32) -> Result<Vec<DirEntry>, io::Error> {
    let mut result_paths = Vec::new();
    for entry in WalkDir::new(path).max_depth(1) {
        let entry = entry.unwrap();
        let pod_path = entry.path();
        for entry in WalkDir::new(pod_path).max_depth(1) {
            let entry = entry.unwrap();
            let path = entry.path();

            let metadata = fs::metadata(&path).unwrap();
            let last_modified = metadata.modified().unwrap().elapsed().unwrap().as_secs();

            // println!("{} {}", path.to_str().unwrap(), last_modified);
            if last_modified > 24 * 3600 * (outdated_days as u64) {
                result_paths.push(entry);
            }
        }
    }
    return Ok(result_paths);
}

fn get_pod_cache_path() -> String {
    let mut result = String::new();
    result.push_str(home_dir().unwrap().to_str().unwrap());
    result.push_str(APPENDED_POD_CACHE_PATH);
    result
}

pub fn clean(outdated_days: i32) {
    let pod_cache_path = get_pod_cache_path();
    let rust_folder_path = Path::new(&pod_cache_path);

    if rust_folder_path.exists() == false {
        println!(
            "{} doesn't exist!",
            rust_folder_path.to_str().unwrap().red()
        );
        return;
    }

    let outdated_paths = get_outdated_pods(rust_folder_path, outdated_days);

    if let Ok(paths) = outdated_paths {
        if paths.len() == 0 {
            println!(
                "{}",
                format!("未找大于 {} 天未使用的pod cache", outdated_days).green()
            );
            return;
        }

        let mut path_and_size: Vec<(PathBuf, FileSize)> = paths
            .into_iter()
            .map(|entry| {
                let path = entry.into_path();
                let size = get_size(&path);
                return (path, size);
            })
            .collect();

        path_and_size.sort_by(|a, b| {
            return a.1.sort(&(b.1));
        });

        let info_to_print: Vec<String> = path_and_size
            .iter()
            .map(|tuple| {
                let mut print_path_str =
                    String::from(tuple.0.to_str().unwrap().green().to_string());
                print_path_str
                    .push_str(format!(", size: {}", tuple.1.size_to_print().red()).as_str());
                return print_path_str;
            })
            .collect();

        let total_size: f64 = path_and_size.iter().fold(0.0, |acc, tuple| {
            acc + if let FileSize::B(byte) = tuple.1 {
                byte
            } else {
                0.0
            }
        });

        println!("{}", info_to_print.join("\n"));
        println!(
            "找到 {} 个超过 {} 天未使用的pod缓存，删除预计可释放 { } 磁盘空间",
            info_to_print.len().to_string().green(),
            format!("{}", outdated_days).green(),
            FileSize::B(total_size).size_to_print().green()
        );
        println!("是否删除? y/n");

        let mut input = String::new();
        io::stdin()
            .read_line(&mut input)
            .expect("Failed to read line");

        let all_paths: Vec<String> = path_and_size
            .iter()
            .map(|tuple| tuple.0.to_str().unwrap().to_string())
            .collect();
        if input.trim() == "y" || input.trim() == "Y" {
            // delete
            for path in all_paths {
                let command = format!("rm -rf {}", path);
                run_command(command);
            }
        } else {
            println!("{}", "取消删除".red());
        }
    } else {
        println!("{}", "获取路径错误.".red())
    }
}
