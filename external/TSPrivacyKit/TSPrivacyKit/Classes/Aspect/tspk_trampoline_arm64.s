#include "TSPKMacros.h"

#if defined(__arm64__)
.text
.align 14
onEntry:
    .quad 0
onExit:
    .quad 0
pMalloc:
    .quad 0
pFree:
    .quad 0

.align 14
.globl SYMBOL_NAME(pns_forwarding_trampoline_page)
.globl SYMBOL_NAME(pns_forwarding_trampoline_stret_page)
SYMBOL_NAME(pns_forwarding_trampoline_stret_page):
SYMBOL_NAME(pns_forwarding_trampoline_page):

SYMBOL_NAME(pns_forwarding_trampoline):
stp     fp, lr, [sp, #-16]! // set up frame pointers
mov     fp, sp
//save context at the beginning
stp x20, x21, [sp, #-16]! //save callee
stp x8, x19, [sp, #-16]! // save callee and struct return
stp x6, x7, [sp, #-16]! // save all regs used in parameter passing
stp x4, x5, [sp, #-16]!
stp x2, x3, [sp, #-16]!
stp x0, x1, [sp, #-16]!
stp d6, d7, [sp, #-32]!
stp d4, d5, [sp, #-32]!
stp d2, d3, [sp, #-32]!
stp d0, d1, [sp, #-32]!

sub x20, lr, #0x0c       // x20 = lr - 12, that is the address of the corresponding `mov x19, lr` instruction of the current trampoline
sub x20, x20, #0x4000   // x20 = x20 - 16384, point to oriImp

mov x0, #0x150
ldr x19, pMalloc
blr x19 //call malloc
mov x19, x0

str x20, [x19, #0x140] //save the oriImp
//ldr lr, [sp], #16 //load lr

ldp d0, d1, [sp], #32 //restore context
ldp d2, d3, [sp], #32
ldp d4, d5, [sp], #32
ldp d6, d7, [sp], #32
ldp x0, x1, [sp], #16
ldp x2, x3, [sp], #16
ldp x4, x5, [sp], #16
ldp x6, x7, [sp], #16
ldp x8, x21, [sp], #16 //x19==x21
stp x8, x21, [x19, #0x10] //x19==x21, store x8, x19 actually
ldp x20, x21, [sp], #16 //!!!!it will override x20, which point to oriImp previously

//save context
stp x20, x21,  [x19, #0x00]
//stp x8, x19, [x19, #0x10]
stp x6, x7,  [x19, #0x20]
stp x4, x5,  [x19, #0x30]
stp x2, x3,  [x19, #0x40]
stp x0, x1,  [x19, #0x50]

stp d6, d7,  [x19, #0x60]
stp d4, d5,  [x19, #0x80]
stp d2, d3,  [x19, #0x100]
stp d0, d1,  [x19, #0x120]

//stp fp, lr, [sp, #-16]! // set up frame pointers
//mov fp, sp
ldr x20, [x19, #0x140] //oriImp
ldp x0, x1,  [x19, #0x50]
ldr x2, [x20, #0x08]   // third argument is pointer to oriCmd
ldr x3, [x20]      // fourth argument is ori imp
ldr x4, [sp, #0x20]      // fifth argument is return address
ldr x21, onEntry
blr x21         // call onEntry routine
mov x21, x0     // original implementation to call is returned

// Restore the stack pointer, frame pointer and link register
//mov    sp, fp
//ldp    fp, lr, [sp], #16

//restore context
ldr x20,     [x19, #0x00]
ldr x8,      [x19, #0x10]
ldp x6, x7,  [x19, #0x20]
ldp x4, x5,  [x19, #0x30]
ldp x2, x3,  [x19, #0x40]
ldp x0, x1,  [x19, #0x50]

ldp d6, d7,  [x19, #0x60]
ldp d4, d5,  [x19, #0x80]
ldp d2, d3,  [x19, #0x100]
ldp d0, d1,  [x19, #0x120]

//stp     fp, lr, [sp, #-16]! // set up frame pointers
//mov     fp, sp

blr x21          // call original implemntation

// Restore the stack pointer, frame pointer and link register
//mov     sp, fp
//ldp     fp, lr, [sp], #16

//save context after calling ori imp
ldp x20, x21,  [x19, #0x00]
stp x20, x21, [sp, #-16]!
ldp x8, x21, [x19, #0x10]
stp x8, x21, [sp, #-16]!// x21==x19
stp x6, x7, [sp, #-16]! // save all regs used in parameter passing
stp x4, x5, [sp, #-16]!
stp x2, x3, [sp, #-16]!
stp x0, x1, [sp, #-16]!
stp d6, d7, [sp, #-32]!
stp d4, d5, [sp, #-32]!
stp d2, d3, [sp, #-32]!
stp d0, d1, [sp, #-32]!

//stp fp, lr, [sp, #-16]! // set up frame pointers
//mov fp, sp
ldp x0, x1,  [x19, #0x50]
ldr x20, [x19, #0x140] //x20 point to oriImp
ldr x2, [x20, #0x08]   // third argument is pointer to oriCmd
ldr x21, onExit
blr x21 // call onExit routine

// Restore the stack pointer, frame pointer and link register
//mov     sp, fp
//ldp     fp, lr, [sp], #16

//stp fp, lr, [sp, #-16]! // set up frame pointers
//mov fp, sp

mov x0, x19 // move the address of the memory to x0, first argument
//ldr x19, [x19, #0x00] //x19 has the previous lr
ldr x21, pFree
blr x21 //call free

ldp d0, d1, [sp], #32
ldp d2, d3, [sp], #32
ldp d4, d5, [sp], #32
ldp d6, d7, [sp], #32
ldp x0, x1, [sp], #16
ldp x2, x3, [sp], #16
ldp x4, x5, [sp], #16
ldp x6, x7, [sp], #16
ldp x8, x19,[sp], #16
ldp x20,x21,[sp], #16

// Restore the stack pointer, frame pointer and link register
mov     sp, fp
ldp     fp, lr, [sp], #16

ret          // return to caller
.align 5
# Save lr, which contains the address to where we need to branch back after function returns, then jump to the actual trampoline implementation
.rept 500
stp     fp, lr, [sp, #-16]! // set up frame pointers
mov     fp, sp
//mov x19, lr
bl SYMBOL_NAME(pns_forwarding_trampoline);
mov     sp, fp
ldp     fp, lr, [sp], #16
ret
.align 4
.endr
#endif
