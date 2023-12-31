use std::num::ParseFloatError;
use std::path::{Path, PathBuf};
use crate::cmd::run_func;

// 和仓库相关，比如获取根目录路径等

pub enum LarkTimeError {
    CannotGetPath
}

type LarkTimeResult<T> = Result<T, LarkTimeError>;

pub fn find_lark_time_root_path() -> LarkTimeResult<PathBuf> {
    // 这里做完善一点应该智能的寻找根目录，最大可能容错。 现在简化处理，直接拿git的根目录，也就是LarkTime的根目录
    return match run_func("git rev-parse --show-toplevel".to_string()) {
        Ok(git_root_path) => {
            println!("find root path {}", git_root_path);
            Ok(PathBuf::from(git_root_path))
        },
        Err(e) => {
            println!("git rev-parse --show-toplevel error {}", e);
            Err(LarkTimeError::CannotGetPath)
        }
    };
}