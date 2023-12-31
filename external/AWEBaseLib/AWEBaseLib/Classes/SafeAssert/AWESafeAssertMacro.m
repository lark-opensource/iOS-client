//
//  AWESafeAssertMacro.m
//  AWESafeAssertMacro
//
//  Created by yaheng on 2020/04/13.
//  Copyright © 2019 yaheng.zheng All rights reserved.
//

#if defined(DEBUG)

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#define DYLD_LIBRARY_PATH "DYLD_LIBRARY_PATH"

static bool i_awe_safe_assert_is_enable = true;

int enable_awe_safe_assert(void)
{
    return i_awe_safe_assert_is_enable = true;
}

int disable_awe_safe_assert(void)
{
    return i_awe_safe_assert_is_enable = false;
}

bool awe_safe_assert_is_enable(void)
{
    if (getenv(DYLD_LIBRARY_PATH) &&
        i_awe_safe_assert_is_enable) {
        return true;
    }
    
    return false;
}

// 需要考虑是否更换为项目内的 LOG 库并写入日志
void awe_safe_assert_log(const char *file, int line, const char *condition, const char *reason)
{
    printf("‼️‼️[AWESafeAssert]‼️‼️ This is a breakpoint☕️! \nIf you don't care, you can execute ` continue ` or ` c ` in the lldb console to continue running the program🏄‍♂️.\nIf you don't want to encounter this assertion again, please execute ` call disable_awe_safe_assert(); ` in the lldb console to disable this function⛷. \n\n [%s:%d] \n condition:%s \n reason:%s \n\n", file, line, condition, reason);
}

#undef DYLD_LIBRARY_PATH

#endif
