//
//  HMDEnvCheck.c
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by yuanzhangjing on 2020/2/6.
//

#include "HMDEnvCheck.h"
#include <sys/mount.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <signal.h>
#include "HMDCompactUnwind.hpp"

static bool check_files_exist(void) {
    char *paths[] = {
        "/usr/libexec/cydia/firmware.sh",
        "/Applications/Cydia.app",
        "/etc/ssh/sshd_config",
        "/Applications/MxTube.app",
        "/Applications/FakeCarrier.app",
        "/Library/MobileSubstrate/CydiaSubstrate.dylib",
        "/jb/offsets.plist", // unc0ver
        "/.cydia_no_stash", // unc0ver
        "/.bootstrapped_electra", // electra
        "/etc/apt/sources.list.d/sileo.sources", // electra
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/bin/ssh",
        "/bin/bash",
        "/private/var/Users/",
        "/private/var/lib/cydia",
        "/Applications/blackra1n.app",
        "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/private/var/log/syslog",
        "/usr/libexec/sftp-server",
        "/jb/amfid_payload.dylib", // unc0ver
        "/etc/apt/undecimus/undecimus.list", // unc0ver
        "/.installed_unc0ver", // unc0ver
        "/etc/apt/sources.list.d/electra.list", // electra
        "/usr/sbin/sshd",
        "/private/var/lib/apt",
        "/jb/jailbreakd.plist", // unc0ver
        "/var/lib/dpkg/info/mobilesubstrate.md5sums", // unc0ver
        "/Applications/IntelliScreen.app",
        "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        "/private/var/cache/apt/",
        "/jb/libjailbreak.dylib", // unc0ver
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/usr/share/jailbreak/injectme.plist", // unc0ver
        "/usr/bin/sshd",
        "/usr/libexec/ssh-keysign",
        "/Applications/SBSettings.app",
        "/private/var/tmp/cydia.log",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/var/log/apt",
        "/usr/sbin/frida-server", // frida
        "/usr/lib/libjailbreak.dylib", // electra
        "/jb/lzma", // electra
        "/Applications/WinterBoard.app",
        "/private/var/stash",
        "/Applications/RockApp.app",
        "/bin/sh",
        "/Applications/Icy.app",
        "/etc/apt",
        "/var/lib/cydia",
    };
    int len = sizeof(paths)/sizeof(char *);
    for (int i = 0; i < len; i++) {
        char *path = paths[i];
        struct statfs s;
        int ret = statfs(path, &s);
        if (ret == 0) {
            return true;
        }
    }

    return false;
}

// remove abnormal path for mac
static bool check_files_exist_mac(void) {
    char *paths[] = {
        "/jb/jailbreakd.plist", // unc0ver
        "/private/var/stash",
        "/Applications/RockApp.app",
        "/Applications/IntelliScreen.app",
        "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        "/jb/lzma", // electra
        "/usr/share/jailbreak/injectme.plist", // unc0ver
        "/etc/apt/sources.list.d/sileo.sources", // electra
        "/etc/apt",
        "/var/log/apt",
        "/private/var/log/syslog",
        "/Applications/SBSettings.app",
        "/var/lib/dpkg/info/mobilesubstrate.md5sums", // unc0ver
        "/Library/MobileSubstrate/CydiaSubstrate.dylib",
        "/jb/libjailbreak.dylib", // unc0ver
        "/.installed_unc0ver", // unc0ver
        "/.bootstrapped_electra", // electra
        "/private/var/tmp/cydia.log",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/jb/offsets.plist", // unc0ver
        "/usr/lib/libjailbreak.dylib", // electra
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/private/var/lib/cydia",
        "/Applications/WinterBoard.app",
        "/private/var/Users/",
        "/jb/amfid_payload.dylib", // unc0ver
        "/.cydia_no_stash", // unc0ver
        "/usr/libexec/cydia/firmware.sh",
        "/etc/apt/undecimus/undecimus.list", // unc0ver
        "/etc/apt/sources.list.d/electra.list", // electra
        "/usr/sbin/frida-server", // frida
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/Applications/Icy.app",
        "/var/lib/cydia",
        "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        "/Applications/blackra1n.app",
        "/private/var/cache/apt/",
        "/private/var/lib/apt",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/Applications/Cydia.app",
        "/Applications/FakeCarrier.app",
        "/usr/bin/sshd",
        "/Applications/MxTube.app",
    };
    int len = sizeof(paths)/sizeof(char *);
    for (int i = 0; i < len; i++) {
        char *path = paths[i];
        struct statfs s;
        int ret = statfs(path, &s);
        if (ret == 0) {
            return true;
        }
    }

    return false;
}

static bool check_file_create(void) {
    char *path = "/hmd_tmp_file";
    int fd = open_dprotected_np(path, O_RDWR | O_CREAT, 0x3, 0, 0644);
    if (fd >= 0) {
        close(fd);
        remove(path);
        return true;
    }
    return false;
}
/*
static bool check_fk(void) {
    pid_t ret = fork();
    if (ret >= 0) {
        if (ret > 0) {
            kill(ret, SIGTERM);
        }
        return true;
    }

    return false;
}
 */

bool hmd_env_regular_check(bool is_mac) {
    //check file exist
    if (is_mac) {
        if (check_files_exist_mac()) {
            return false;
        }
    }else{
        if (check_files_exist()) {
            return false;
        }
    }

    //check file create
    if (check_file_create()) {
        return false;
    }
    
    /*fork() 会对objc的所有lock加锁，容易引发死锁，详见objc4-779.1 _objc_atfork_prepare()源码*/
    //check api
//    if (check_fk()) {
//        return false;
//    }
    
    return true;
}

static bool check_image(void) {
    __block bool ret = false;
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        char *names[] = {
            "SubstrateLoader",
            "MobileSubstrate",
            "TweakInject",
            "CydiaSubstrate",
            "libsubstrate",
        };
        int len = sizeof(names)/sizeof(char *);
        for (int i = 0; i < len; i++) {
            char *name = names[i];
            const char *image_path = image->macho_image.name;
            if (image_path) {
                if (strstr(image_path, name) != NULL) {
                    ret = true;
                    *stop = true;
                    break;
                }
            }
        }
    });
    return ret;
}

bool hmd_env_image_check(void) {
    if (check_image()) {
        return false;
    }
    return true;
}
