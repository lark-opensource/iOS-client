#if defined(__arm__)

#include "TSPKMacros.h"
#include <arm/arch.h>

# Write out the trampoline table, aligned to the page boundary
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
.globl SYMBOL_NAME(pns_forwarding_trampoline_stret_page)
SYMBOL_NAME(pns_forwarding_trampoline_stret_page):
SYMBOL_NAME(pns_forwarding_trampoline):
push {r0-r3, r7-r11} //save context to stack temporarily
sub r6, #0x1000        // r6 = r6 - 4096, that is where the data for this trampoline is stored
sub r6, #0xc     // the pointer to oriImp is stored with an offset of 8

//calculate the address of onEntry
mov r4, r6
mov r4, r4, LSR #12
mov r4, r4, LSL #12 // r4 point to the onEntry

//alloc heap memory to store context
mov r0, #0x40
ldr r5, [r4, #0x8] //load the func pointer to malloc
blx r5 //call malloc
mov r5, r0

pop {r0-r3, r7-r11} //pop the context

str r0, [r5, #0x0]
str r1, [r5, #0x4]
str r2, [r5, #0x8]
str r3, [r5, #0xc]
str r4, [r5, #0x10] //point to the address of onEntry
//str r5, [r5, #0x14] //suppose to save original r5
str r6, [r5, #0x18] //r6 store the address of oriImp
str r7, [r5, #0x1c]
str r8, [r5, #0x20]
str r9, [r5, #0x24]
str r10, [r5, #0x28]
str r11, [r5, #0x2c]
//str r4, [r5, #0x30] //suppose to save original r4
//str lr, [r5, #0x34]
//str r6, [r5, #0x38] //suppose to save original r6

mov r7, r5 //now r7 point to heap
pop {r4-r6, lr}
str r4, [r7, #0x30] //save original r4
str r5, [r7, #0x14] //save original r5
str lr, [r7, #0x34] //save lr
str r6, [r7, #0x38] //suppose to save original r6

ldr r4, [r7, #0x10] //r4 point to the address of onEntry
ldr r5, [r7, #0x18] //r5 point to oriImp

sub sp, #0x4
str lr, [sp] //5th argument is ret address

ldr r0, [r7, #0x4] //1st argument is instance or class
ldr r1, [r7, #0x8] //2nd arugment is cmd
ldr r2, [r5, #0x4] //3rd argument is oriCmd
ldr r3, [r5]       //4th argument is oriImp

//calculate the address of onEntry
ldr r5, [r4] //now, we get the address of onEntry
blx r5 //call onEntry
mov r5, r0 //the actual imp to call, assign it to r5
add sp, sp, #0x4 //restore the stack

ldr r0, [r7, #0x0]
ldr r1, [r7, #0x4]
ldr r2, [r7, #0x8]
ldr r3, [r7, #0xc]
ldr r4, [r7, #0x30] //original r4
//ldr r5, [r7, #0x14] //original r5
ldr r6, [r7, #0x38] //original r6
//ldr r7, [r7, #0x1c] //original r7
ldr r8, [r7, #0x20]
ldr r9, [r7, #0x24]
ldr r10, [r7, #0x28]
ldr r11, [r7, #0x2c]

blx r5 //call oriImp

ldr r5, [r7, #0x14] //restore original r5
ldr lr, [r7, #0x34] //the lr
push {r0-r6, r8-r11, lr} //save the context after calling oriImp

ldr r4, [r7, #0x10] //r4 point to the address of onEntry
ldr r5, [r7, #0x18] //r5 point to oriImp

//load the first and second arguments
ldr r0, [r7, #0x4] //1st argument is instance or class
ldr r1, [r7, #0x8] //2nd arugment is cmd
ldr r2, [r5, #0x4] //3rd argument is oriCmd
//calculate the address of onExit
ldr r5, [r4, #0x4] //now we get the onExit
blx r5 //call onExit

mov r0, r7
ldr r7, [r0, #0x1c] //restore r7
ldr r5, [r4, #0xc] //now we get the pFree
blx r5 //call free

pop {r0-r6, r8-r11, pc} //restore context for called oriImp
.align 4

.rept 239
push {r4-r6, lr}
# Save pc+8 into r6, then jump to the actual trampoline implementation
mov r6, pc
b SYMBOL_NAME(pns_forwarding_trampoline);
nop
//.align 4
.endr

#endif
