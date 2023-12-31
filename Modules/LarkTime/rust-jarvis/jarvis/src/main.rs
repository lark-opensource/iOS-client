mod clean;
mod cmd;
mod filesize;
mod i18n;
mod install;
mod larktime;
mod open;
mod podfile;

use crate::clean::clean;
use crate::i18n::{open, deduplicate_and_sort_keys};
use crate::install::install;
use clap::arg;
use clap::{App, AppSettings, Arg};
use cmd_lib;
use cmd_lib::run_cmd;
use colored::*;

fn main() {

    let open_cmd = App::new("open")
        .about("open Demo WorkSpace");

    let install_cmd = App::new("install")
        .arg(arg!(repo_update: -u)
            .help("pod install with --repo-update"))
        .arg(arg!(with_IM: -m)
            .help("pod install with IM"))
        .about("install pods");

    let i18n_cmd = App::new("i18n")
        .setting(AppSettings::SubcommandRequiredElseHelp)
        .about("deal with i18n keys")
        .subcommand(App::new("sort")
            .about("open calendar i18n yaml file."))
        .subcommand(App::new("open")
            .about("sort keys"));

    let clean_pod_cache_cmd = App::new("clean_pod_cache")
        .arg(arg!(<OUT_DATED_DAYS> "outdated days")
            .required(false))
        .about("find and clean useless pod cache");

    let app = App::new("jarvis")
        .bin_name("jarvis")
        .setting(AppSettings::SubcommandRequiredElseHelp)
        .subcommand(open_cmd)
        .subcommand(install_cmd)
        .subcommand(clean_pod_cache_cmd)
        .subcommand(i18n_cmd);

    let matches = app.get_matches();
    match matches.subcommand() {
        Some(("open", matches)) => {
            open::open();
        }
        Some(("install", matches)) => {
            install(matches.is_present("repo_update"), matches.is_present("with_IM"));
        }
        Some(("clean_pod_cache", matches)) => {
            let out_dated_days = matches.value_of("OUT_DATED_DAYS").unwrap_or("30");
            let days: i32 = out_dated_days.parse().unwrap_or(30);
            clean(days);
        }
        Some(("i18n", matches)) => match matches.subcommand() {
            Some(("open", matches)) => {
                println!("open i18n yaml file");
                open();
            }
            Some(("sort", matches)) => {
                println!("Found i18n yaml changed, to avoid conflicts, de-duplicating and sorting keys before committing...");
                deduplicate_and_sort_keys();
            }
            _ => unreachable!("fatal error"),
        },
        _ => unreachable!("fatal error"),
    }
}
