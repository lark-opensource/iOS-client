use std::collections::HashMap;
use std::path::{Path, PathBuf};
use yaml_rust::{YamlLoader, YamlEmitter, Yaml};
use std::fs;
use std::fs::copy;
use std::iter::Map;
use std::ops::Index;
use itertools::Itertools;
use linked_hash_map::LinkedHashMap;
use yaml_rust::Yaml::{Array, Hash};
use crate::cmd::run_command;
use crate::larktime::find_lark_time_root_path;


const CALENDAR_I18N_YAML_PATH_REL: &str = "Bizs/Calendar/configurations/i18n/i18n.strings.yaml";

fn get_yaml_path() -> Option<PathBuf> {
    return match find_lark_time_root_path() {
        Ok(root_path) => {
            let mut i18n_path = PathBuf::new();
            i18n_path.push(root_path);
            i18n_path.push(CALENDAR_I18N_YAML_PATH_REL);
            Some(i18n_path)
        },
        Err(e) => {
            println!("could not get root path!");
            None
        }
    }
}

pub fn open() {
    if let Some(yaml_path) = get_yaml_path() {
        run_command(format!("open {}", yaml_path.to_str().unwrap()));
    }
}

pub fn deduplicate_and_sort_keys() {
    if let Some(yaml_path) = get_yaml_path() {
        let content = fs::read_to_string(&yaml_path).unwrap();
        let prefix_desc = content.chars()
            .take_while(|&ch| ch != 'C')
            .collect::<String>();

        let mut calendar_yaml = YamlLoader::load_from_str(&content).unwrap();

        if let Some(Array(keys_array)) = calendar_yaml.pop().unwrap().into_hash().unwrap().remove(&Yaml::from_str("Calendar")) {
            let mut unique_keys= keys_array.into_iter().unique().collect::<Vec<_>>();
            unique_keys.sort();

            let mut map = LinkedHashMap::new();
            map.insert(Yaml::String(String::from("Calendar")), Yaml::Array(unique_keys));

            let calendar_hash_yaml = Yaml::Hash(map);
            let mut keys_str = String::new();

            {
                let mut emitter = YamlEmitter::new(&mut keys_str);
                let out = emitter.dump(&calendar_hash_yaml).unwrap();
            }

            fs::write(&yaml_path, [prefix_desc, keys_str.trim_start_matches("---\n").to_string()].concat());
        } else {
            println!("Wrong format! Please check !");
        }
    }
}