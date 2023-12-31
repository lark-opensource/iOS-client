//
// Created by NewPan on 2021/9/17.
//

#include <cstdlib>
#include <cstdio>

namespace TmpDir {
    /// 只实现了 unix 系的非安卓系统.
    /// https://doc.rust-lang.org/std/env/fn.temp_dir.html
    /// Returns the value of the TMPDIR environment variable if it is set, otherwise for non-Android it returns /tmp. If Android, since there is no global temporary folder (it is usually allocated per-app), it returns /data/local/tmp.
    std::string tmpDir() {
        char *pathvar;
        pathvar = getenv("TMPDIR");
        if (pathvar) {
            return std::string(pathvar);
        }

        return "/tmp/";
    }
}