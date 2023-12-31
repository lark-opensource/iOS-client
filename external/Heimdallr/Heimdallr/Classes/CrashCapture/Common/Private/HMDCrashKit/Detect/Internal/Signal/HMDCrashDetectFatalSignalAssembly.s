//
//  HMDCrashDetectFatalSignalAssembly.s
//  Pods
//
//  Created by bytedance on 2023/6/12.
//

#if __arm64__ && __LP64__

#define HMD_CSF_CRASH_MESSAGE \
"[CRASH][FATAL][Stack Check Failed] Your program has crashed because of stack check failed which means your program has overwritten some part of stack spaces which does not belong to you. This kind of crash often happens when your code writes data that exceeded the size of the array allocated on the stack. Please check out your program, especially where stack allocations are made. And be sure all your read & write operations do not exceed the size of variables on the stack. If you have any questions, please get in touch with the Slardar iOS team for help."


/********************************************************************
 * [Macro] PUSH_FRAME
 * [Macro] POP_FRAME
 * push and pop frame if no stack variables
 ********************************************************************/

.macro PUSH_FRAME
stp    fp, lr, [sp, #-16]!
mov    fp, sp
.endmacro

.macro POP_FRAME
mov    sp, fp
ldp    fp, lr, [sp], #16
.endmacro

/********************************************************************
 * [Macro] GLOBAL_ENTRY
 * [Macro] STATIC_ENTRY
 * [Macro] END_ENTRY
 * mark function begin and end entry
 ********************************************************************/

.macro GLOBAL_ENTRY functionName
.text
.private_extern \functionName
.globl          \functionName
.p2align 2
\functionName:
.endmacro

.macro STATIC_ENTRY functionName
.text
.p2align 2
\functionName:
.endmacro

.macro END_ENTRY functionName
LExit\functionName:
.endmacro

.macro UNWIND functionName unwind_flags
    .section __LD,__compact_unwind,regular,debug
    .quad \functionName
    .set  LUnwind\functionName, LExit\functionName - \functionName
    .long LUnwind\functionName
    .long \unwind_flags
    .quad 0     /* no personality */
    .quad 0     /* no LSDA */
.endmacro

#define NoFrame          0x02000000  // no frame, no SP adjustment
#define FrameWithNoSaves 0x04000000  // frame, no non-volatile saves

/********************************************************************
 * [Function] void __stack_chk_fail(void)
 * internal entrance for __stack_chk_fail
 ********************************************************************/

GLOBAL_ENTRY ___stack_chk_fail

    PUSH_FRAME

    bl HMD_CSF_CRASH_MESSAGE

    POP_FRAME
    ret

END_ENTRY ___stack_chk_fail

/********************************************************************
 * [Function] void #description#(void)
 * log some info for stack check failed
 ********************************************************************/

// STATIC_ENTRY HMD_CSF_CRASH_MESSAGE
.text
.p2align 2
HMD_CSF_CRASH_MESSAGE:

    PUSH_FRAME

    bl _stack_check_failed_process

    POP_FRAME
    ret

// END_ENTRY HMD_CSF_CRASH_MESSAGE
LExit_HMD_CSF_CRASH_MESSAGE:

/********************************************************************
 * [UNWIND INFO] used to backtrace this function
 ********************************************************************/

UNWIND ___stack_chk_fail, FrameWithNoSaves

// UNWIND HMD_CSF_CRASH_MESSAGE, FrameWithNoSaves
.section __LD,__compact_unwind,regular,debug
.quad HMD_CSF_CRASH_MESSAGE
.set  LUnwind_HMD_CSF_CRASH_MESSAGE, LExit_HMD_CSF_CRASH_MESSAGE - HMD_CSF_CRASH_MESSAGE
.long LUnwind_HMD_CSF_CRASH_MESSAGE
.long FrameWithNoSaves
.quad 0     /* no personality */
.quad 0     /* no LSDA */

.subsections_via_symbols

#endif
