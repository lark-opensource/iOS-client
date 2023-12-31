//
//  HMDISAHookOptimizationAssembly.s
//  Pods
//
//  Created by sunrunwang on 2023/5/17.
//

#if __arm64__ && __LP64__

/********************************************************************
 * [Macro] Global Control
 * control function behavior
 ********************************************************************/

#define ISA_MAGIC_STORE_REGISTER_NAME   x7
#define ISA_MAGIC_COMPARE_REGISTER_NAME x8

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

.macro END_ENTRY functionName
LExit\functionName:
.endmacro

/********************************************************************
 * [MacroType] TYPE_STATIC TYPE_EXTERN
 * mark macro type as static or extern
 ********************************************************************/

#define TYPE_STATIC 0
#define TYPE_EXTERN 1

/********************************************************************
 * [Macro] DECLARE_POINTER (TYPE_STATIC|TYPE_EXTERN) pointerName
 * declare a pointer
 ********************************************************************/

.macro DECLARE_POINTER type pointerName
.if     \type == TYPE_STATIC
    .zerofill       __DATA,__bss,\pointerName,8,3
.elseif \type == TYPE_EXTERN
    .private_extern \pointerName
    .globl          \pointerName
    .zerofill       __DATA,__common,\pointerName,8,3
.else
    ERROR_type_declare_not_found
.endif
.endmacro

/********************************************************************
 * [Macro] DECLARE_BOOL (TYPE_STATIC|TYPE_EXTERN) boolName
 * declare a pointer
 ********************************************************************/

.macro DECLARE_BOOL type boolName
.if     \type == TYPE_STATIC
    .zerofill       __DATA,__bss,\boolName,1,0
.elseif \type == TYPE_EXTERN
    .private_extern \boolName
    .globl          \boolName
    .zerofill       __DATA,__common,\boolName,1,0
.else
    ERROR_type_declare_not_found
.endif
.endmacro

/********************************************************************
 * [Macro] REG_MAGIC registerName
 * mark register with magic value
 ********************************************************************/

.macro REG_SET_MAGIC registerName
    mov    \registerName, #64207
    movk   \registerName, #65261, lsl #16
    movk   \registerName, #64207, lsl #32
    movk   \registerName, #65261, lsl #48
.endmacro

/********************************************************************
 * [Macro] REG_CLEAR registerName
 * clear register with zero value
 ********************************************************************/

.macro REG_CLEAR registerName
    mov    \registerName, #0
.endmacro

/********************************************************************
 * UNWIND functionName, unwind_flags
 * Unwind info generation with no personality and LSDA
 ********************************************************************/

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
 * [Pointer] HMDISAHookOptimization_previous_function
 * previous Swift hook point
 ********************************************************************/

DECLARE_POINTER TYPE_EXTERN, _HMDISAHookOptimization_previous_function

/********************************************************************
 * [Pointer] HMDISAHookOptimization_main_thread_mark
 * main thread mark
 ********************************************************************/

DECLARE_BOOL    TYPE_STATIC, _HMDISAHookOptimization_main_thread_mark

/********************************************************************
 * [Function] int HMDISAHookOptimization_before_objc_allocate_classPair(void)
 * mark register with magic value before allocate class Pair
 ********************************************************************/

GLOBAL_ENTRY _HMDISAHookOptimization_before_objc_allocate_classPair

    PUSH_FRAME

    bl _pthread_main_np             ; test if main thread
    cbz x0, LocalLabel_justReturn

    mov     w9, #1
    adrp    x8,      _HMDISAHookOptimization_main_thread_mark@PAGE
    strb    w9, [x8, _HMDISAHookOptimization_main_thread_mark@PAGEOFF]

    REG_SET_MAGIC ISA_MAGIC_STORE_REGISTER_NAME

LocalLabel_justReturn:

    POP_FRAME
    ret

END_ENTRY _HMDISAHookOptimization_before_objc_allocate_classPair

/********************************************************************
 * [UNWIND INFO] used to backtrace this function
 ********************************************************************/

UNWIND _HMDISAHookOptimization_before_objc_allocate_classPair, FrameWithNoSaves

/********************************************************************
 * [Function] void HMDISAHookOptimization_after_objc_allocate_classPair(int)
 * clear register with magic value after allocate class Pair
 ********************************************************************/

GLOBAL_ENTRY _HMDISAHookOptimization_after_objc_allocate_classPair

    cbz x0, LocalLabel_justReturn2

    REG_CLEAR ISA_MAGIC_STORE_REGISTER_NAME

    mov     w9, #0
    adrp    x8,      _HMDISAHookOptimization_main_thread_mark@PAGE
    strb    w9, [x8, _HMDISAHookOptimization_main_thread_mark@PAGEOFF]

LocalLabel_justReturn2:

    ret

END_ENTRY _HMDISAHookOptimization_after_objc_allocate_classPair

/********************************************************************
 * [UNWIND INFO] used to backtrace this function
 ********************************************************************/

UNWIND _HMDISAHookOptimization_after_objc_allocate_classPair, NoFrame

/********************************************************************
 * [Function] BOOL HMDISAHookOptimization_objc_hook_getClass(const char *name, Class *outClass)
 * hooked objc_hook_getClass
 ********************************************************************/

GLOBAL_ENTRY _HMDISAHookOptimization_objc_hook_getClass

    REG_SET_MAGIC ISA_MAGIC_COMPARE_REGISTER_NAME
    cmp ISA_MAGIC_STORE_REGISTER_NAME, ISA_MAGIC_COMPARE_REGISTER_NAME
    b.eq LocalLabel_maybeOptimization

    adrp   x8,      _HMDISAHookOptimization_previous_function@PAGE
    ldr    x2, [x8, _HMDISAHookOptimization_previous_function@PAGEOFF]
    br     x2

LocalLabel_maybeOptimization:

    stp    x20, x19, [sp, #-32]!    ; [x0, x1] space, [decrease SP]
    stp    x29, x30, [sp, #16]      ; push frame
    add    x29, sp,  #16            ; new  frame

    mov    x19, x1                  ; store x1
    mov    x20, x0                  ; store x0
    
    
    bl     _pthread_main_np             ; test if main thread
    cbz    x0, LocalLabel_previousFunction

    adrp   x8,      _HMDISAHookOptimization_main_thread_mark@PAGE
    ldrb   w0, [x8, _HMDISAHookOptimization_main_thread_mark@PAGEOFF]

                                    ; test if not enabled
    cbz   w0, LocalLabel_previousFunction

    mov    x1,  x19                 ; restore x1
    str    xzr, [x1]                ; store zero inside x1
    
    ldp    x29, x30, [sp, #16]      ; pop frame
    ldp    x20, x19, [sp], #32      ; [x20, x19] restored

    ; mov  w0, #0                   ; already zero
    ret                             ; return NO

LocalLabel_previousFunction:

    adrp   x8,      _HMDISAHookOptimization_previous_function@PAGE
    ldr    x2, [x8, _HMDISAHookOptimization_previous_function@PAGEOFF]
    
    mov    x0, x20                  ; restore x0
    mov    x1, x19                  ; restore x1

    ldp    x29, x30, [sp, #16]      ; pop frame
    ldp    x20, x19, [sp], #32      ; [x20, x19] restored

    br     x2

END_ENTRY _HMDISAHookOptimization_objc_hook_getClass

.section __LD,__compact_unwind,regular,debug
.quad _HMDISAHookOptimization_objc_hook_getClass
.set  LUnwind_objc_hook_getClass_first_part, LocalLabel_maybeOptimization - _HMDISAHookOptimization_objc_hook_getClass
.long LUnwind_objc_hook_getClass_first_part
.long NoFrame
.quad 0             /* no personality */
.quad 0             /* no LSDA */

.section __LD,__compact_unwind,regular,debug
.quad LocalLabel_maybeOptimization
.set  LUnwind_objc_hook_getClass_second_part, LExit_HMDISAHookOptimization_objc_hook_getClass - LocalLabel_maybeOptimization
.long LUnwind_objc_hook_getClass_second_part
.long 0x84000001    /* not function start, stack pushed, x19, x20 saved */
.quad 0             /* no personality */
.quad 0             /* no LSDA */

/********************************************************************
 * [mark] subsections_via_symbols
 ********************************************************************/

.subsections_via_symbols

#endif /* __arm64__ && __LP64__ */
