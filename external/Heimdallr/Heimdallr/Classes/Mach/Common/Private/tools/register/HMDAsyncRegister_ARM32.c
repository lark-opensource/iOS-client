//
//  HMDAsyncRegister_ARM32.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#if defined(__arm__)

#include "hmd_types.h"

static const char* register_names[] = {"r0", "r1",  "r2",  "r3", "r4", "r5", "r6", "r7",  "r8", "r9", "r10", "r11", "ip", "sp", "lr", "pc", "cpsr"};
static const char* exception_register_names[] = {"exception", "fsr", "far"};

uintptr_t hmd_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    if (regNumber <= 12) {
        return context->__ss.__r[regNumber];
    }
    switch (regNumber) {
        case 13:
            return context->__ss.__sp;
        case 14:
            return context->__ss.__lr;
        case 15:
            return context->__ss.__pc;
        case 16:
            return context->__ss.__cpsr;
    }
    return 0;
}

uintptr_t hmd_exception_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    switch (regNumber) {
        case 0:
            return context->__es.__exception;
        case 1:
            return context->__es.__fsr;
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
