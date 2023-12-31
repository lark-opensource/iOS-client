//
// Created by bytedance on 2020/12/2.
//

#ifndef STRATEGYCENTER_UNIQUE_FD_H
#define STRATEGYCENTER_UNIQUE_FD_H

#include "vc_base.h"
#include "vc_unique_object.h"

#include <dirent.h>
#include <unistd.h>

VC_NAMESPACE_BEGIN

struct UniqueFDTraits {
    static int InvalidValue() {
        return -1;
    }

    static bool IsValid(int value) {
        return value >= 0;
    }

    static void Free(int fd) {
        close(fd);
    };
};

using UniqueFD = VCUniqueObject<int, UniqueFDTraits>;

VC_NAMESPACE_END

#endif // STRATEGYCENTER_UNIQUE_FD_H
