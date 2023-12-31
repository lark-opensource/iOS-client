#include "TSPKMacros.h"

#if defined(__x86_64__)
.text
.align 12
onEntry:
    .quad 0
onExit:
    .quad 0
pMalloc:
    .quad 0
pFree:
    .quad 0

.align 12
.globl SYMBOL_NAME(pns_forwarding_trampoline_page)
SYMBOL_NAME(pns_forwarding_trampoline_page):
SYMBOL_NAME(pns_forwarding_trampoline):

pushq %rbp
movq %rsp, %rbp //alignment to 16bytes

//save context
pushq   %rax
pushq   %r10
pushq   %r9
pushq   %r8
pushq   %rbx
pushq   %rcx
pushq   %rdx
pushq   %rsi
pushq   %rdi
pushq   %r15
pushq   %r14
pushq   %r13
pushq   %r12
pushq   %r11 //0x70 bytes space
subq    $0x80, %rsp // make space for floating point registers and save
movdqa  %xmm0, 0x70(%rsp)
movdqa  %xmm1, 0x60(%rsp)
movdqa  %xmm2, 0x50(%rsp)
movdqa  %xmm3, 0x40(%rsp)
movdqa  %xmm4, 0x30(%rsp)
movdqa  %xmm5, 0x20(%rsp)
movdqa  %xmm6, 0x10(%rsp)
movdqa  %xmm7, 0x00(%rsp)

leaq    pMalloc(%rip), %r13
//save the context
movq $0x120, %rdi
callq *(%r13) //call malloc

//restore all context
movdqa 0x00(%rsp), %xmm7
movdqa 0x10(%rsp), %xmm6
movdqa 0x20(%rsp), %xmm5
movdqa 0x30(%rsp), %xmm4
movdqa 0x40(%rsp), %xmm3
movdqa 0x50(%rsp), %xmm2
movdqa 0x60(%rsp), %xmm1
movdqa 0x70(%rsp), %xmm0
addq    $0x80, %rsp
popq    %r11
popq    %r12
popq    %r13
popq    %r14
popq    %r15
popq    %rdi
popq    %rsi
popq    %rdx
popq    %rcx
popq    %rbx
popq    %r8
popq    %r9
popq    %r10
//popq    %rax

movq    %r12,  0x60(%rax) //store r12 first
movq    %rax, %r12 //callee register r12 points to the heap memory. Note that r12 is saved
popq    %rax

//save the context to heap
movq %r10, 0x0(%r12)
movq %r9,  0x8(%r12)
movq %r8,  0x10(%r12)
movq %rbx, 0x18(%r12)
movq %rax, 0x20(%r12)
movq %rcx,  0x28(%r12)
movq %rdx,  0x30(%r12)
movq %rsi,  0x38(%r12)
movq %rdi,  0x40(%r12)
movq %r15,  0x48(%r12)
movq %r14,  0x50(%r12)
movq %r13,  0x58(%r12)
//movq %r12,  0x60(%rax)
movq %r11,  0x68(%r12)
movdqa  %xmm0, 0x70(%r12)
movdqa  %xmm1, 0x80(%r12)
movdqa  %xmm2, 0x90(%r12)
movdqa  %xmm3, 0xa0(%r12)
movdqa  %xmm4, 0xb0(%r12)
movdqa  %xmm5, 0xc0(%r12)
movdqa  %xmm6, 0xd0(%r12)
movdqa  %xmm7, 0xe0(%r12)
movq    %rsp,   0xF0(%r12) //save what: rbp
//movq    %xx,   0xF8(%r12) //save oriSEL
movq    0x08(%rsp), %r13
movq    %r13,   0x100(%r12) //save what: ret addr for "callq pns_forwarding_trampoline"
movq    0x10(%rsp), %r13
movq    %r13,   0x108(%r12) //save what: last rbp
movq    0x18(%rsp), %r13
movq    %r13,   0x110(%r12) //save what: ret addr for "trampoline entry"


movq   0x08(%rsp), %r13 //the address of the first nop in entry instructions, which is the return address of "callq pns_forwarding_trampoline"

subq    $4096+9, %r13   // the oriImp
movq    0x08(%r13), %r14 //the oriSEL
movq    %r14,   0xF8(%r12) //save oriSEL

//the 1rs and 2nd arguments are kept same as caller
movq    0xF8(%r12), %rdx //3rd arguments is pointer to ori selector
movq    (%r13), %rcx    // 4th argument is pointer to ori imp
movq    0x18(%rsp), %r8      // 5th argument is original return address
leaq    onEntry(%rip), %r13
callq   *(%r13)         // call onEntry routine (saves return address)
movq    %rax, %r13      // pointer to original implementation returned

//unwind the stack
movq %rbp, %rsp
popq %rbp  //pop rbp
popq %r14  //pop ret of last callq
movq %rbp, %rsp
popq %rbp  //pop rbp
popq %r14  //pop ret of trmpoline

//restore the context
movq  0x0(%r12)   ,  %r10
movq  0x8(%r12)   ,  %r9
movq  0x10(%r12)  ,  %r8
movq  0x18(%r12)  ,  %rbx
movq  0x20(%r12)  ,  %rax
movq   0x28(%r12) ,  %rcx
movq   0x30(%r12) ,  %rdx
movq   0x38(%r12) ,  %rsi
movq   0x40(%r12) ,  %rdi
movq   0x48(%r12) ,  %r15
movq   0x50(%r12) ,  %r14
//movq   0x58(%r12) ,  %r13
//movq   0x60(%r12) ,  %r12
movq   0x68(%r12) ,  %r11
movsd 0x70(%r12),  %xmm0
movsd 0x80(%r12),  %xmm1
movsd 0x90(%r12),  %xmm2
movsd 0xa0(%r12),  %xmm3
movsd 0xb0(%r12),  %xmm4
movsd 0xc0(%r12),  %xmm5
movsd 0xd0(%r12),  %xmm6
movsd 0xe0(%r12),  %xmm7

callq    *%r13   // call original implementation

//re-wind the stack
movq    0x110(%r12), %r13 //save what: ret addr for "trampoline entry"
pushq %r13
pushq %rbp //save what: last rbp
movq %rsp, %rbp
movq    0x100(%r12), %r13 //save what: ret addr for "callq pns_forwarding_trampoline"
pushq %r13
pushq %rbp //save what: rbp
movq %rsp, %rbp

//prepare arguments for next call
movq 0x40(%r12), %r14 //first argument %rdi
movq 0x38(%r12), %r15 //second argument %rsi

//save the context after calling oriImp
movq %r10, 0x0(%r12)
movq %r9,  0x8(%r12)
movq %r8,  0x10(%r12)
movq %rbx, 0x18(%r12)
movq %rax, 0x20(%r12)
movq %rcx,  0x28(%r12)
movq %rdx,  0x30(%r12)
movq %rsi,  0x38(%r12)
movq %rdi,  0x40(%r12)
//movq %r15,  0x48(%r12)
//movq %r14,  0x50(%r12)
//movq %r13,  0x58(%r12)
//movq %r12,  0x60(%r12)
movq %r11,  0x68(%r12)
movdqa  %xmm0, 0x70(%r12)
movdqa  %xmm1, 0x80(%r12)
movdqa  %xmm2, 0x90(%r12)
movdqa  %xmm3, 0xa0(%r12)
movdqa  %xmm4, 0xb0(%r12)
movdqa  %xmm5, 0xc0(%r12)
movdqa  %xmm6, 0xd0(%r12)
movdqa  %xmm7, 0xe0(%r12)

movq    %r14, %rdi
movq    %r15, %rsi
movq    0xF8(%r12), %rdx //3rd arguments is pointer to ori selector
leaq    onExit(%rip), %r13
callq   *(%r13)         // call on exit routine

//restore the context for after calling oriImp
movq  0x0(%r12)   ,  %r10
movq  0x8(%r12)   ,  %r9
movq  0x10(%r12)  ,  %r8
movq  0x18(%r12)  ,  %rbx
movq  0x20(%r12)  ,  %rax
movq   0x28(%r12) ,  %rcx
movq   0x30(%r12) ,  %rdx
movq   0x38(%r12) ,  %rsi
movq   0x40(%r12) ,  %rdi
movq   0x48(%r12) ,  %r15
movq   0x50(%r12) ,  %r14
movq   0x58(%r12) ,  %r13 //need to restore the callee register now
//movq   0x60(%r12) ,  %r12
movq   0x68(%r12) ,  %r11
movsd 0x70(%r12),  %xmm0
movsd 0x80(%r12),  %xmm1
movsd 0x90(%r12),  %xmm2
movsd 0xa0(%r12),  %xmm3
movsd 0xb0(%r12),  %xmm4
movsd 0xc0(%r12),  %xmm5
movsd 0xd0(%r12),  %xmm6
movsd 0xe0(%r12),  %xmm7

//push all registers and free the heap
subq    $0x70, %rsp
movq  %r10, 0x00(%rsp)
movq  %r9,  0x08(%rsp)
movq  %r8,  0x10(%rsp)
movq  %rbx, 0x18(%rsp)
movq  %rax,  0x20(%rsp)
movq  %rcx,  0x28(%rsp)
movq  %rdx,  0x30(%rsp)
movq  %rsi,  0x38(%rsp)
movq  %rdi,  0x40(%rsp)
movq  %r15,  0x48(%rsp)
movq  %r14,  0x50(%rsp)
movq  %r13,  0x58(%rsp)
//movq  %r12,  0x60(%rsp) //no need because it points to heap memory
movq  %r11,  0x68(%rsp)

subq    $0x80, %rsp // make space for floating point registers and save
movdqa  %xmm0, 0x70(%rsp)
movdqa  %xmm1, 0x60(%rsp)
movdqa  %xmm2, 0x50(%rsp)
movdqa  %xmm3, 0x40(%rsp)
movdqa  %xmm4, 0x30(%rsp)
movdqa  %xmm5, 0x20(%rsp)
movdqa  %xmm6, 0x10(%rsp)
movdqa  %xmm7, 0x00(%rsp)

leaq    pFree(%rip), %r13
movq    %r12, %rdi
movq    0x60(%r12),  %r12 //finally, need to restore the callee register
callq   *(%r13) //call free

//pop the context, restore all registers
movdqa 0x00(%rsp), %xmm7
movdqa 0x10(%rsp), %xmm6
movdqa 0x20(%rsp), %xmm5
movdqa 0x30(%rsp), %xmm4
movdqa 0x40(%rsp), %xmm3
movdqa 0x50(%rsp), %xmm2
movdqa 0x60(%rsp), %xmm1
movdqa 0x70(%rsp), %xmm0
addq    $0x80, %rsp

movq  0x00(%rsp),   %r10
movq  0x08(%rsp),   %r9
movq  0x10(%rsp),   %r8
movq  0x18(%rsp),   %rbx
movq   0x20(%rsp),  %rax
movq   0x28(%rsp),  %rcx
movq   0x30(%rsp),  %rdx
movq   0x38(%rsp),  %rsi
movq   0x40(%rsp),  %rdi
movq   0x48(%rsp),  %r15
movq   0x50(%rsp),  %r14
movq   0x58(%rsp),  %r13
//movq   0x60(%rsp),  %r12
movq   0x68(%rsp),  %r11
addq    $0x70, %rsp

movq %rbp, %rsp
popq    %rbp    // restore frame pointer

//pushq %r14
//jmpq *%r14//---jump to caller
retq
.align 4 // align the trampolines at 16 bytes (required for config page lookup and sizing)

.rept 182
pushq %rbp
movq %rsp, %rbp //alignment
// Call into the dispatcher, placing our return address on the stack.
call SYMBOL_NAME(pns_forwarding_trampoline) //5bytes
movq %rbp, %rsp
popq    %rbp
retq
.align 4 // align the trampolines at 16 bytes (required for config page lookup and sizing)
.endr

#endif
