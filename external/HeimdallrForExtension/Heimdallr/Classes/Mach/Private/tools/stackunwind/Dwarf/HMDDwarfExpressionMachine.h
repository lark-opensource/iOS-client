//
//  HMDDwarfExpressionMachine.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#pragma once

#import "HMDDwarfConfig.h"

#if HMD_USE_DWARF_UNWIND

#include <stdbool.h>
#include <stdint.h>
#include "HMDAsyncThreadState.h"

#define HMD_DWARF_EXPRESSION_STACK_SIZE (100)

typedef struct {
  intptr_t buffer[HMD_DWARF_EXPRESSION_STACK_SIZE];
  intptr_t *pointer;
} HMDDwarfExpressionStack;

typedef struct {
  HMDDwarfExpressionStack stack;
  const void *dataCursor;
  const void *endAddress;
  const hmd_thread_state_t *registers;
} HMDDwarfExpressionMachine;

__BEGIN_DECLS

void HMDDwarfExpressionStackInit(HMDDwarfExpressionStack *stack);
bool HMDDwarfExpressionStackIsValid(HMDDwarfExpressionStack *stack);
bool HMDDwarfExpressionStackPush(HMDDwarfExpressionStack *stack, intptr_t value);
intptr_t HMDDwarfExpressionStackPeek(HMDDwarfExpressionStack *stack);
intptr_t HMDDwarfExpressionStackPop(HMDDwarfExpressionStack *stack);

bool HMDDwarfExpressionMachineInit(HMDDwarfExpressionMachine *machine,
                                      const void *cursor,
                                      const hmd_thread_state_t *registers,
                                      intptr_t stackValue);
bool HMDDwarfExpressionMachinePrepareForExecution(HMDDwarfExpressionMachine *machine);
bool HMDDwarfExpressionMachineIsFinished(HMDDwarfExpressionMachine *machine);
bool HMDDwarfExpressionMachineGetResult(HMDDwarfExpressionMachine *machine, intptr_t *result);

bool HMDDwarfExpressionMachineExecuteNextOpcode(HMDDwarfExpressionMachine *machine);

bool HMDDwarfUnwindSetRegisterValue(hmd_thread_state_t *registers,uint64_t num, uintptr_t value);
uintptr_t HMDDwarfUnwindGetRegisterValue(const hmd_thread_state_t *registers, uint64_t num);

__END_DECLS

#endif
