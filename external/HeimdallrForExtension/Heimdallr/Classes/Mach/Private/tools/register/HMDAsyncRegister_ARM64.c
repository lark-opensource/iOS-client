//
//  HMDAsyncRegister_ARM64.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#if defined(__arm64__)

#include "hmd_types.h"

static const char* register_names[] = {
"x0",  "x1",  "x2",  "x3",  "x4",  "x5",  "x6",  "x7",  "x8",
"x9",  "x10", "x11", "x12", "x13", "x14", "x15", "x16", "x17",
"x18", "x19", "x20", "x21", "x22", "x23", "x24", "x25", "x26",
"x27", "x28", "fp",  "lr",  "sp",  "pc",  "cpsr"
};
static const char* exception_register_names[] = {"exception", "esr", "far"};

uintptr_t hmd_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    if (regNumber <= 28) {
        return context->__ss.__x[regNumber];
    }

    switch (regNumber) {
        case 29:
            return HMD_POINTER_STRIP(context->__ss.__fp);
        case 30:
            return HMD_POINTER_STRIP(context->__ss.__lr);
        case 31:
            return HMD_POINTER_STRIP(context->__ss.__sp);
        case 32:
            return HMD_POINTER_STRIP(context->__ss.__pc);
        case 33:
            return context->__ss.__cpsr;
    }
    return 0;
}

uintptr_t hmd_exception_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    switch (regNumber) {
        case 0:
            return context->__es.__exception;
        case 1:
            return context->__es.__esr;
        case 2:
            return context->__es.__far;
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
