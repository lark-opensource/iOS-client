use colored::*;
use cmd_lib::{run_cmd, run_fun};

// 执行对应的command命令，无结果
pub fn run_command(cmd: String) {
    println!("{}",cmd.green());
    run_cmd!(bash -c $cmd);
}

// 执行对应的命令，获取结果
pub fn run_func(cmd: String) -> Result<String, std::io::Error> {
    return run_fun!(bash -c $cmd)
}