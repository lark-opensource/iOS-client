
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
 * void HMDUSELForwarder_IMP_resolved_method_implementation(void)
 * entry point for USEL forwarder
 ********************************************************************/
GLOBAL_ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation
UNWIND _HMDUSELForwarder_IMP_resolved_method_implementation, NoFrame

mov     x0, #0
mov     x1, #0
movi    d0, #0
movi    d1, #0
movi    d2, #0
movi    d3, #0

ret

END_ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

#elif __x86_64__

.macro ENTRY functionName
    .text
    .globl    \functionName
    .align    6, 0x90
\functionName:
.endmacro

.macro END_ENTRY functionName
LExit\functionName:
.endmacro

/********************************************************************
* UNWIND name, flags
* Unwind info generation
********************************************************************/
.macro UNWIND
   .section __LD,__compact_unwind,regular,debug
   .quad $0
   .set  LUnwind$0, LExit$0 - $0
   .long LUnwind$0
   .long $1
   .quad 0     /* no personality */
   .quad 0  /* no LSDA */
   .text
.endmacro

#define NoFrame 0x02010000           // no frame, no SP adjustment except return address
#define FrameWithNoSaves 0x01000000  // frame, no non-volatile saves

/********************************************************************
 * void HMDUSELForwarder_IMP_resolved_method_implementation(void)
 * entry point for USEL forwarder
 ********************************************************************/
ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation
UNWIND _HMDUSELForwarder_IMP_resolved_method_implementation, NoFrame

pushq   %rbp
movq    %rsp, %rbp
xorl    %eax, %eax
popq    %rbp
retq

END_ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

#elif __arm__

.macro ENTRY functionName
    .text
    .thumb
    .align 5
    .globl \functionName
    .thumb_func
\functionName:
.endmacro

.macro END_ENTRY functionName
LExit\functionName:
.endmacro

/********************************************************************
 * void HMDUSELForwarder_IMP_resolved_method_implementation(void)
 * entry point for USEL forwarder
 ********************************************************************/
ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

mov       r0, #0
mov       r1, #0
mov       r2, #0
mov       r3, #0
vmov.i32  q0, #0
vmov.i32  q1, #0
vmov.i32  q2, #0
vmov.i32  q3, #0
bx        lr

END_ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

#elif __i386__

.macro ENTRY functionName
    .text
    .globl    \functionName
    .align    4, 0x90
\functionName:
.endmacro

.macro END_ENTRY
.endmacro

/********************************************************************
 * void HMDUSELForwarder_IMP_resolved_method_implementation(void)
 * entry point for USEL forwarder
 ********************************************************************/
ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

pushl    %ebp
movl    %esp, %ebp
xorl    %eax, %eax
popl    %ebp
retl

END_ENTRY _HMDUSELForwarder_IMP_resolved_method_implementation

#else
#error unsupported platform
#endif  /* __arm64__ && __LP64__ */
