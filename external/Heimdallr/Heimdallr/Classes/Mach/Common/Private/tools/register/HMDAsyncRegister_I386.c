//
//  HMDAsyncRegister_I386.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#if defined(__i386__)

#include "hmd_types.h"

static const char* register_names[] = {"eax", "ebx", "ecx", "edx", "edi", "esi", "ebp", "esp", "ss", "eflags", "eip", "cs", "ds", "es", "fs", "gs"};
static const char* exception_register_names[] = {"trapno", "err", "faultvaddr"};

uintptr_t hmd_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    switch (regNumber) {
        case 0:
            return context->__ss.__eax;
        case 1:
            return context->__ss.__ebx;
        case 2:
            return context->__ss.__ecx;
        case 3:
            return context->__ss.__edx;
        case 4:
            return context->__ss.__edi;
        case 5:
            return context->__ss.__esi;
        case 6:
            return context->__ss.__ebp;
        case 7:
            return context->__ss.__esp;
        case 8:
            return context->__ss.__ss;
        case 9:
            return context->__ss.__eflags;
        case 10:
            return context->__ss.__eip;
        case 11:
            return context->__ss.__cs;
        case 12:
            return context->__ss.__ds;
        case 13:
            return context->__ss.__es;
        case 14:
            return context->__ss.__fs;
        case 15:
            return context->__ss.__gs;
    }
    return 0;
}

uintptr_t hmd_exception_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    switch (regNumber) {
        case 0:
            return context->__es.__trapno;
        case 1:
            return context->__es.__err;
        case 2:
            return context->__es.__faultvaddr;
    }
    return 0;
}

static const int register_count = sizeof(register_names) / sizeof(*register_names);

static const int exception_register_count = sizeof(exception_register_names) / sizeof(*exception_register_names);

int hmd_num_registers(void) {
    return register_count;
}

const char* hmd_register_name(const int regNumber) {
    if (regNumber < hmd_num_registers()) {
        return register_names[regNumber];
    }
    return NULL;
}

int hmd_num_exception_registers(void) {
    return exception_register_count;
}

const char* hmd_exception_register_name(const int regNumber) {
    if (regNumber < hmd_num_exception_registers()) {
        return exception_register_names[regNumber];
    }
    return NULL;
}

#endif
