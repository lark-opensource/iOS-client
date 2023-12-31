use crate::cmd::run_command;
use crate::podfile;

pub fn install(repo_update: bool, with_IM: bool) {
    if with_IM {
        podfile::update_podfile_with_IM();
    }
    let command = format!("bundle install && bundle exec pod install {}", if repo_update {"--repo-update"} else {""});
    run_command(command);
}