use std::path::PathBuf;
use crate::cmd::run_command;
use crate::larktime::find_lark_time_root_path;

const DEMO_WORKSPACE_PATH_REL: &str = "CalendarDemo.xcworkspace";

pub fn open() {
    match find_lark_time_root_path() {
        Ok(path) => {
            let mut workspace_path = PathBuf::new();
            workspace_path.push(path);
            workspace_path.push(DEMO_WORKSPACE_PATH_REL);
            run_command(format!("open {}",workspace_path.to_str().unwrap()));
        }
        Err(e) => {
            println!("Open Error");
        }
    }
}