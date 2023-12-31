//
//  HMDAsyncRegister_X86_64.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#if defined(__x86_64__)

#include "hmd_types.h"

static const char* register_names[] = {"rax", "rbx", "rcx", "rdx", "rdi", "rsi", "rbp", "rsp", "r8", "r9", "r10","r11", "r12", "r13", "r14", "r15", "rip", "rflags", "cs",  "fs", "gs"};
static const char* exception_register_names[] = {"trapno", "err", "faultvaddr"};

uintptr_t hmd_register_value(const hmd_thread_state_t* const context, const int regNumber) {
    switch (regNumber) {
        case 0:
            return context->__ss.__rax;
        case 1:
            return context->__ss.__rbx;
        case 2:
            return context->__ss.__rcx;
        case 3:
            return context->__ss.__rdx;
        case 4:
            return context->__ss.__rdi;
        case 5:
            return context->__ss.__rsi;
        case 6:
            return context->__ss.__rbp;
        case 7:
            return context->__ss.__rsp;
        case 8:
            return context->__ss.__r8;
        case 9:
            return context->__ss.__r9;
        case 10:
            return context->__ss.__r10;
        case 11:
            return context->__ss.__r11;
        case 12:
            return context->__ss.__r12;
        case 13:
            return context->__ss.__r13;
        case 14:
            return context->__ss.__r14;
        case 15:
            return context->__ss.__r15;
        case 16:
            return context->__ss.__rip;
        case 17:
            return context->__ss.__rflags;
        case 18:
            return context->__ss.__cs;
        case 19:
            return context->__ss.__fs;
        case 20:
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
