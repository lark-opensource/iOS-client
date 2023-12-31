use std::fs;
use std::path::{Path, PathBuf};
use std::fs::OpenOptions;
use std::fs::File;
use std::io::prelude::*;
use std::ptr::replace;
use yaml_rust::YamlLoader;
use crate::larktime::find_lark_time_root_path;

const DEMO_PODFILE_NAME: &str = "Podfile";
const REPLACE_YAML: &str = "replace.yaml";

pub fn update_podfile_with_IM() {
    // 获取 podfile 文件路径
    let path = find_lark_time_root_path().ok().expect("not find larktime root path");

    // 读取 podfile 文件内容
    let podfile_path = path.join(DEMO_PODFILE_NAME);
    let mut file = OpenOptions::new()
        .read(true)
        .write(true)
        .open(&podfile_path)
        .ok()
        .expect("open podfile error");
    let mut buffer = String::new();
    file.read_to_string(&mut buffer).ok().expect("read podfile content error");
    drop(file);

    // 读取 内容替换yml 文件内容
    let yaml_path = path.join(REPLACE_YAML);
    let content = fs::read_to_string(yaml_path).ok().expect("replace yaml file not found");
    let yaml = YamlLoader::load_from_str(&content).ok().expect("replace yml file content error");
    let yaml_withIM = yaml[0]["podfile"]["withIM"].as_hash().unwrap();
    for (old, new) in yaml_withIM {
        // 更新 podfile 文件内容，文本替换方式是硬编码
        buffer = buffer.replace(&old.as_str().unwrap(), &new.as_str().unwrap());
        fs::write(&podfile_path, &buffer).ok().expect("update podfile with IM error");
    }
}