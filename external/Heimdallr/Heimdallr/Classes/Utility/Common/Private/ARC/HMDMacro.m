//
//  HMDMacro.m
//  Heimdallr
//
//  Created by someone on someday
//

#include <signal.h>
#include <stdbool.h>
#import <sys/sysctl.h>

#include "HMDMacro.h"
#include "hmd_debug.h"

#ifdef DEBUG

#if __arm64__ && __LP64__

asm(
".text\n"
".globl    _HMDMacroDevelopDebugPoint\n"
".p2align 2\n"
"_HMDMacroDevelopDebugPoint:\n"
"    stp    x29, x30, [sp, #-16]!\n"
"    mov    x29, sp\n"
"    bl    _hmddebug_isBeingTraced\n"
"    cbz    w0, Label_exit\n"
"    mov    w0, #2\n"
"    ldp    x29, x30, [sp], #16\n"
"    b    _raise\n"
"Label_exit:\n"
"    ldp    x29, x30, [sp], #16\n"
"    ret\n"
);

#elif __x86_64__

asm(
".text\n"
".globl    _HMDMacroDevelopDebugPoint\n"
"_HMDMacroDevelopDebugPoint:\n"
"    pushq    %rbp\n"
"    movq    %rsp, %rbp\n"
"    callq    _hmddebug_isBeingTraced\n"
"    testb    %al, %al\n"
"    je    Label_exit\n"
"    pushq    $2\n"
"    popq    %rdi\n"
"    popq    %rbp\n"
"    jmp    _raise\n"
"Label_exit:\n"
"    popq    %rbp\n"
"    retq\n"
);

#else

void HMDMacroDevelopDebugPoint(void) {
    if(!hmddebug_isBeingTraced()) return;
    raise(SIGINT);
}

#endif

#endif /* DEBUG */
