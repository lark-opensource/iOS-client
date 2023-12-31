
#if __arm64__ && __LP64__

.macro PUSH_FRAME
stp    fp, lr, [sp, #-16]!
mov    fp, sp
.endmacro

.macro POP_FRAME
mov    sp, fp
ldp    fp, lr, [sp], #16
.endmacro

.macro GLOBAL_ENTRY functionName
.text
.globl   \functionName
.p2align 2
\functionName:
.endmacro

.macro END_ENTRY functionName
LExit\functionName:
.endmacro

/********************************************************************
 * UNWIND functionName, flags
 * Unwind info generation
 ********************************************************************/
.macro UNWIND
    .section __LD,__compact_unwind,regular,debug
    .quad $0
    .set  LUnwind$0, LExit$0 - $0
    .long LUnwind$0
    .long $1
    .quad 0     /* no personality */
    .quad 0     /* no LSDA */
    .text
.endmacro

#define NoFrame          0x02000000  // no frame, no SP adjustment
#define FrameWithNoSaves 0x04000000  // frame, no non-volatile saves

/********************************************************************
 * void hmd_cpp_terminate_wrapped_handle(void)
 * entry point for cpp standard terminate handle
 ********************************************************************/
GLOBAL_ENTRY _hmd_cpp_terminate_wrapped_handle
UNWIND _hmd_cpp_terminate_wrapped_handle, FrameWithNoSaves

PUSH_FRAME

bl _hmd_cpp_terminate_process_handle

adrp    x8,      _hmd_cpp_terminate_original_handle@GOTPAGE
ldr     x8, [x8, _hmd_cpp_terminate_original_handle@GOTPAGEOFF]
ldr     x0, [x8]

POP_FRAME

cbz     x0, LQuickExit
br      x0

LQuickExit:
ret

END_ENTRY _hmd_cpp_terminate_wrapped_handle

#elif __x86_64__

.text
.globl    _hmd_cpp_terminate_wrapped_handle
_hmd_cpp_terminate_wrapped_handle:
.cfi_startproc
pushq    %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
movq    %rsp, %rbp
.cfi_def_cfa_register %rbp
callq   _hmd_cpp_terminate_process_handle
movq    _hmd_cpp_terminate_original_handle@GOTPCREL(%rip), %rax
movq    (%rax), %rax
testq    %rax, %rax
je    LQuickExit
popq     %rbp
jmpq    *%rax
LQuickExit:
popq    %rbp
retq
.cfi_endproc
.subsections_via_symbols

#elif __arm__

.text
.syntax unified
.globl    _hmd_cpp_terminate_wrapped_handle
.p2align  2
.code     16
.thumb_func _hmd_cpp_terminate_wrapped_handle
_hmd_cpp_terminate_wrapped_handle:
push    {r7, lr}
mov      r7, sp
bl      _hmd_cpp_terminate_process_handle
ldr    r0, LCPI0_0
LPC0_0:
add    r0, pc
ldr    r0, [r0]
ldr    r0, [r0]
cbz    r0, LQuickExit
pop.w    {r7, lr}
bx     r0
LQuickExit:
pop   {r7, pc}
.p2align    2

.data_region
LCPI0_0:
.long    L_hmd_cpp_terminate_original_handle$non_lazy_ptr-(LPC0_0+4)
.end_data_region

.section    __DATA,__nl_symbol_ptr,non_lazy_symbol_pointers
.p2align    2
L_hmd_cpp_terminate_original_handle$non_lazy_ptr:
.indirect_symbol    _hmd_cpp_terminate_original_handle
.long    0

.subsections_via_symbols

#elif __i386__

.text
.globl    _hmd_cpp_terminate_wrapped_handle
_hmd_cpp_terminate_wrapped_handle:
.cfi_startproc
pushl    %ebp
.cfi_def_cfa_offset 8
.cfi_offset %ebp, -8
movl    %esp, %ebp
.cfi_def_cfa_register %ebp
pushl    %esi
pushl    %eax
.cfi_offset %esi, -12
calll    L0$pb
L0$pb:
popl    %esi
calll    _hmd_cpp_terminate_process_handle
movl    L_hmd_cpp_terminate_original_handle$non_lazy_ptr-L0$pb(%esi), %eax
movl    (%eax), %eax
addl    $4, %esp
testl    %eax, %eax
je    LBB0_1
popl    %esi
popl    %ebp
jmpl    *%eax
LBB0_1:
popl    %esi
popl    %ebp
retl
.cfi_endproc

.section    __IMPORT,__pointers,non_lazy_symbol_pointers
L_hmd_cpp_terminate_original_handle$non_lazy_ptr:
.indirect_symbol    _hmd_cpp_terminate_original_handle
.long    0

.subsections_via_symbols

#else
#error unsupported platform
#endif  /* __arm64__ && __LP64__ */

