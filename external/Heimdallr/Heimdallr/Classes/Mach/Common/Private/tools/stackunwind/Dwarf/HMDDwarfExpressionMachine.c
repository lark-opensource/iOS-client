//
//  HMDDwarfExpressionMachine.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//


#include "HMDDwarfExpressionMachine.h"

#if HMD_USE_DWARF_UNWIND

#include "HMDDwarfDataParsing.h"
#include "HMDDwarfUnwindRegisters.h"
#include "dwarf.h"
#include "hmd_types.h"
#include "hmd_memory.h"
static bool HMDDwarfExpressionMachineExecute_bregN(HMDDwarfExpressionMachine *machine,
                                                      uint8_t opcode);
static bool HMDDwarfExpressionMachineExecute_deref(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_plus_uconst(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_and(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_plus(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_dup(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_swap(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_deref_size(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_ne(HMDDwarfExpressionMachine *machine);
static bool HMDDwarfExpressionMachineExecute_litN(HMDDwarfExpressionMachine *machine,
                                                     uint8_t opcode);

#pragma mark -
#pragma mark Stack Implementation
void HMDDwarfExpressionStackInit(HMDDwarfExpressionStack *stack) {
  if (!HMD_IS_VALID_PTR(stack)) {
    return;
  }

  memset(stack, 0, sizeof(HMDDwarfExpressionStack));

  stack->pointer = stack->buffer;
}

bool HMDDwarfExpressionStackIsValid(HMDDwarfExpressionStack *stack) {
  if (!HMD_IS_VALID_PTR(stack)) {
    return false;
  }

  // check for valid stack pointer
  if (stack->pointer < stack->buffer) {
    return false;
  }

  if (stack->pointer > stack->buffer + HMD_DWARF_EXPRESSION_STACK_SIZE) {
    return false;
  }

  return true;
}

bool HMDDwarfExpressionStackPush(HMDDwarfExpressionStack *stack, intptr_t value) {
  if (!HMDDwarfExpressionStackIsValid(stack)) {
    return false;
  }

  if (stack->pointer == stack->buffer + HMD_DWARF_EXPRESSION_STACK_SIZE) {
    // overflow
    stack->pointer = NULL;
    return false;
  }

  *(stack->pointer) = value;
  stack->pointer += 1;

  return true;
}

intptr_t HMDDwarfExpressionStackPeek(HMDDwarfExpressionStack *stack) {
  if (!HMDDwarfExpressionStackIsValid(stack)) {
    return 0;
  }

  if (stack->pointer == stack->buffer) {
    // underflow
    stack->pointer = NULL;
    return 0;
  }

  return *(stack->pointer - 1);
}

intptr_t HMDDwarfExpressionStackPop(HMDDwarfExpressionStack *stack) {
  if (!HMDDwarfExpressionStackIsValid(stack)) {
    return 0;
  }

  if (stack->pointer == stack->buffer) {
    // underflow
    stack->pointer = NULL;
    return 0;
  }

  stack->pointer -= 1;

  return *(stack->pointer);
}

#pragma mark -
#pragma mark Machine API
bool HMDDwarfExpressionMachineInit(HMDDwarfExpressionMachine *machine,
                                      const void *cursor,
                                      const hmd_thread_state_t *registers,
                                      intptr_t stackValue) {
  if (!HMD_IS_VALID_PTR(machine)) {
    return false;
  }

  memset(machine, 0, sizeof(HMDDwarfExpressionMachine));

  if (!HMD_IS_VALID_PTR(cursor)) {
    return false;
  }

  machine->dataCursor = cursor;
  machine->registers = registers;

  HMDDwarfExpressionStackInit(&machine->stack);

  return HMDDwarfExpressionStackPush(&machine->stack, stackValue);
}

bool HMDDwarfExpressionMachinePrepareForExecution(HMDDwarfExpressionMachine *machine) {
  if (!HMD_IS_VALID_PTR(machine)) {
    HMDDWLog("Error: invalid inputs\n");
    return false;
  }

  uint64_t expressionLength = HMDDWParseULEB128AndAdvance(&machine->dataCursor);

  if (expressionLength == 0) {
    HMDDWLog("Error: DWARF expression length is zero\n");
    return false;
  }

  machine->endAddress = machine->dataCursor + expressionLength;

  return true;
}

bool HMDDwarfExpressionMachineIsFinished(HMDDwarfExpressionMachine *machine) {
  if (!HMD_IS_VALID_PTR(machine)) {
    HMDDWLog("Error: invalid inputs\n");
    return true;
  }

  if (!HMD_IS_VALID_PTR(machine->endAddress) || !HMD_IS_VALID_PTR(machine->dataCursor)) {
    HMDDWLog("Error: DWARF machine pointers invalid\n");
    return true;
  }

  if (!HMDDwarfExpressionStackIsValid(&machine->stack)) {
    HMDDWLog("Error: DWARF machine stack invalid\n");
    return true;
  }

  return machine->dataCursor >= machine->endAddress;
}

bool HMDDwarfExpressionMachineGetResult(HMDDwarfExpressionMachine *machine,
                                           intptr_t *result) {
  if (!HMD_IS_VALID_PTR(machine) || !HMD_IS_VALID_PTR(result)) {
    return false;
  }

  if (machine->dataCursor != machine->endAddress) {
    HMDDWLog("Error: DWARF expression hasn't completed execution\n");
    return false;
  }

  *result = HMDDwarfExpressionStackPeek(&machine->stack);

  return HMDDwarfExpressionStackIsValid(&machine->stack);
}

bool HMDDwarfExpressionMachineExecuteNextOpcode(HMDDwarfExpressionMachine *machine) {
  if (!HMD_IS_VALID_PTR(machine)) {
    return false;
  }

  const uint8_t opcode = HMDDWParseUint8AndAdvance(&machine->dataCursor);

  bool success = false;

  switch (opcode) {
    case HMD_DW_OP_deref:
      success = HMDDwarfExpressionMachineExecute_deref(machine);
      break;
    case HMD_DW_OP_dup:
      success = HMDDwarfExpressionMachineExecute_dup(machine);
      break;
    case HMD_DW_OP_and:
      success = HMDDwarfExpressionMachineExecute_and(machine);
      break;
    case HMD_DW_OP_plus:
      success = HMDDwarfExpressionMachineExecute_plus(machine);
      break;
    case HMD_DW_OP_swap:
      success = HMDDwarfExpressionMachineExecute_swap(machine);
      break;
    case HMD_DW_OP_plus_uconst:
      success = HMDDwarfExpressionMachineExecute_plus_uconst(machine);
      break;
    case HMD_DW_OP_ne:
      success = HMDDwarfExpressionMachineExecute_ne(machine);
      break;
    case HMD_DW_OP_lit0:
    case HMD_DW_OP_lit1:
    case HMD_DW_OP_lit2:
    case HMD_DW_OP_lit3:
    case HMD_DW_OP_lit4:
    case HMD_DW_OP_lit5:
    case HMD_DW_OP_lit6:
    case HMD_DW_OP_lit7:
    case HMD_DW_OP_lit8:
    case HMD_DW_OP_lit9:
    case HMD_DW_OP_lit10:
    case HMD_DW_OP_lit11:
    case HMD_DW_OP_lit12:
    case HMD_DW_OP_lit13:
    case HMD_DW_OP_lit14:
    case HMD_DW_OP_lit15:
    case HMD_DW_OP_lit16:
    case HMD_DW_OP_lit17:
    case HMD_DW_OP_lit18:
    case HMD_DW_OP_lit19:
    case HMD_DW_OP_lit20:
    case HMD_DW_OP_lit21:
    case HMD_DW_OP_lit22:
    case HMD_DW_OP_lit23:
    case HMD_DW_OP_lit24:
    case HMD_DW_OP_lit25:
    case HMD_DW_OP_lit26:
    case HMD_DW_OP_lit27:
    case HMD_DW_OP_lit28:
    case HMD_DW_OP_lit29:
    case HMD_DW_OP_lit30:
    case HMD_DW_OP_lit31:
      success = HMDDwarfExpressionMachineExecute_litN(machine, opcode);
      break;
    case HMD_DW_OP_breg0:
    case HMD_DW_OP_breg1:
    case HMD_DW_OP_breg2:
    case HMD_DW_OP_breg3:
    case HMD_DW_OP_breg4:
    case HMD_DW_OP_breg5:
    case HMD_DW_OP_breg6:
    case HMD_DW_OP_breg7:
    case HMD_DW_OP_breg8:
    case HMD_DW_OP_breg9:
    case HMD_DW_OP_breg10:
    case HMD_DW_OP_breg11:
    case HMD_DW_OP_breg12:
    case HMD_DW_OP_breg13:
    case HMD_DW_OP_breg14:
    case HMD_DW_OP_breg15:
    case HMD_DW_OP_breg16:
    case HMD_DW_OP_breg17:
    case HMD_DW_OP_breg18:
    case HMD_DW_OP_breg19:
    case HMD_DW_OP_breg20:
    case HMD_DW_OP_breg21:
    case HMD_DW_OP_breg22:
    case HMD_DW_OP_breg23:
    case HMD_DW_OP_breg24:
    case HMD_DW_OP_breg25:
    case HMD_DW_OP_breg26:
    case HMD_DW_OP_breg27:
    case HMD_DW_OP_breg28:
    case HMD_DW_OP_breg29:
    case HMD_DW_OP_breg30:
    case HMD_DW_OP_breg31:
      success = HMDDwarfExpressionMachineExecute_bregN(machine, opcode);
      break;
    case HMD_DW_OP_deref_size:
      success = HMDDwarfExpressionMachineExecute_deref_size(machine);
      break;
    default:
      HMDDWLog("Error: Unrecognized DWARF expression opcode 0x%x\n", opcode);
      return false;
  }

  return success;
}

#pragma mark -
#pragma mark Helpers
static intptr_t HMDDwarfExpressionMachineStackPop(HMDDwarfExpressionMachine *machine) {
  return HMDDwarfExpressionStackPop(&machine->stack);
}

static bool HMDDwarfExpressionMachineStackPush(HMDDwarfExpressionMachine *machine,
                                                  intptr_t value) {
  return HMDDwarfExpressionStackPush(&machine->stack, value);
}

#pragma mark -
#pragma mark Opcode Implementations
static bool HMDDwarfExpressionMachineExecute_bregN(HMDDwarfExpressionMachine *machine,
                                                      uint8_t opcode) {
  // find the register number, compute offset value, push
  const uint8_t regNum = opcode - HMD_DW_OP_breg0;

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: DW_OP_breg invalid register number\n");
    return false;
  }

  int64_t offset = HMDDWParseLEB128AndAdvance(&machine->dataCursor);

  HMDDWLog("DW_OP_breg %d value %d\n", regNum, (int)offset);

  const intptr_t value =
      HMDDwarfUnwindGetRegisterValue(machine->registers, regNum) + (intptr_t)offset;

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_deref(HMDDwarfExpressionMachine *machine) {
  // pop stack, dereference, push result
  intptr_t value = HMDDwarfExpressionMachineStackPop(machine);

  HMDDWLog("DW_OP_deref value %p\n", (void *)value);

  if (hmd_async_read_memory(value, &value, sizeof(value)) != HMD_ESUCCESS) {
    HMDDWLog("Error: DW_OP_deref failed to read memory\n");
    return false;
  }

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_plus_uconst(HMDDwarfExpressionMachine *machine) {
  // pop stack, add constant, push result
  intptr_t value = HMDDwarfExpressionMachineStackPop(machine);

  value += HMDDWParseULEB128AndAdvance(&machine->dataCursor);

  HMDDWLog("DW_OP_plus_uconst value %lu\n", value);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_and(HMDDwarfExpressionMachine *machine) {
  HMDDWLog("DW_OP_plus_and\n");

  intptr_t value = HMDDwarfExpressionMachineStackPop(machine);

  value = value & HMDDwarfExpressionMachineStackPop(machine);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_plus(HMDDwarfExpressionMachine *machine) {
  HMDDWLog("DW_OP_plus\n");

  intptr_t value = HMDDwarfExpressionMachineStackPop(machine);

  value = value + HMDDwarfExpressionMachineStackPop(machine);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_dup(HMDDwarfExpressionMachine *machine) {
  // duplicate top of stack
  intptr_t value = HMDDwarfExpressionStackPeek(&machine->stack);

  HMDDWLog("DW_OP_dup value %lu\n", value);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_swap(HMDDwarfExpressionMachine *machine) {
  // swap top two values on the stack
  intptr_t valueA = HMDDwarfExpressionMachineStackPop(machine);
  intptr_t valueB = HMDDwarfExpressionMachineStackPop(machine);

  HMDDWLog("DW_OP_swap\n");

  if (!HMDDwarfExpressionMachineStackPush(machine, valueA)) {
    return false;
  }

  return HMDDwarfExpressionMachineStackPush(machine, valueB);
}

static bool HMDDwarfExpressionMachineExecute_deref_size(HMDDwarfExpressionMachine *machine) {
  // pop stack, dereference variable sized value, push result
  const void *address = (const void *)HMDDwarfExpressionMachineStackPop(machine);
  const uint8_t readSize = HMDDWParseUint8AndAdvance(&machine->dataCursor);
  intptr_t value = 0;

  HMDDWLog("DW_OP_deref_size %p size %u\n", address, readSize);

  switch (readSize) {
    case 1:
      value = HMDDWParseUint8AndAdvance(&address);
      break;
    case 2:
      value = HMDDWParseUint16AndAdvance(&address);
      break;
    case 4:
      value = HMDDWParseUint32AndAdvance(&address);
      break;
    case 8:
      // this is a little funky, as an 8 here really doesn't make sense for 32-bit platforms
      value = (intptr_t)HMDDWParseUint64AndAdvance(&address);
      break;
    default:
      HMDDWLog("Error: unrecognized DW_OP_deref_size argument %x\n", readSize);
      return false;
  }

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_ne(HMDDwarfExpressionMachine *machine) {
  HMDDWLog("DW_OP_ne\n");

  intptr_t value = HMDDwarfExpressionMachineStackPop(machine);

  value = value != HMDDwarfExpressionMachineStackPop(machine);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

static bool HMDDwarfExpressionMachineExecute_litN(HMDDwarfExpressionMachine *machine,
                                                     uint8_t opcode) {
  const uint8_t value = opcode - HMD_DW_OP_lit0;

  HMDDWLog("DW_OP_lit %u\n", value);

  return HMDDwarfExpressionMachineStackPush(machine, value);
}

bool HMDDwarfUnwindSetRegisterValue(hmd_thread_state_t *registers,uint64_t num, uintptr_t value) {
    switch (num) {
      case HMD_DWARF_ARM64_X0:
        registers->__ss.__x[0] = value;
        return true;
      case HMD_DWARF_ARM64_X1:
        registers->__ss.__x[1] = value;
        return true;
      case HMD_DWARF_ARM64_X2:
        registers->__ss.__x[2] = value;
        return true;
      case HMD_DWARF_ARM64_X3:
        registers->__ss.__x[3] = value;
        return true;
      case HMD_DWARF_ARM64_X4:
        registers->__ss.__x[4] = value;
        return true;
      case HMD_DWARF_ARM64_X5:
        registers->__ss.__x[5] = value;
        return true;
      case HMD_DWARF_ARM64_X6:
        registers->__ss.__x[6] = value;
        return true;
      case HMD_DWARF_ARM64_X7:
        registers->__ss.__x[7] = value;
        return true;
      case HMD_DWARF_ARM64_X8:
        registers->__ss.__x[8] = value;
        return true;
      case HMD_DWARF_ARM64_X9:
        registers->__ss.__x[9] = value;
        return true;
      case HMD_DWARF_ARM64_X10:
        registers->__ss.__x[10] = value;
        return true;
      case HMD_DWARF_ARM64_X11:
        registers->__ss.__x[11] = value;
        return true;
      case HMD_DWARF_ARM64_X12:
        registers->__ss.__x[12] = value;
        return true;
      case HMD_DWARF_ARM64_X13:
        registers->__ss.__x[13] = value;
        return true;
      case HMD_DWARF_ARM64_X14:
        registers->__ss.__x[14] = value;
        return true;
      case HMD_DWARF_ARM64_X15:
        registers->__ss.__x[15] = value;
        return true;
      case HMD_DWARF_ARM64_X16:
        registers->__ss.__x[16] = value;
        return true;
      case HMD_DWARF_ARM64_X17:
        registers->__ss.__x[17] = value;
        return true;
      case HMD_DWARF_ARM64_X18:
        registers->__ss.__x[18] = value;
        return true;
      case HMD_DWARF_ARM64_X19:
        registers->__ss.__x[19] = value;
        return true;
      case HMD_DWARF_ARM64_X20:
        registers->__ss.__x[20] = value;
        return true;
      case HMD_DWARF_ARM64_X21:
        registers->__ss.__x[21] = value;
        return true;
      case HMD_DWARF_ARM64_X22:
        registers->__ss.__x[22] = value;
        return true;
      case HMD_DWARF_ARM64_X23:
        registers->__ss.__x[23] = value;
        return true;
      case HMD_DWARF_ARM64_X24:
        registers->__ss.__x[24] = value;
        return true;
      case HMD_DWARF_ARM64_X25:
        registers->__ss.__x[25] = value;
        return true;
      case HMD_DWARF_ARM64_X26:
        registers->__ss.__x[26] = value;
        return true;
      case HMD_DWARF_ARM64_X27:
        registers->__ss.__x[27] = value;
        return true;
      case HMD_DWARF_ARM64_X28:
        registers->__ss.__x[28] = value;
        return true;
      case HMD_DWARF_ARM64_FP:
        hmd_thread_state_set_fp(registers, value);
        return true;
      case HMD_DWARF_ARM64_SP:
        hmd_thread_state_set_sp(registers, value);
        return true;
      case HMD_DWARF_ARM64_LR:
        // Here's what's going on. For x86, the "return register" is virtual. The architecture
        // doesn't actually have one, but DWARF does have the concept. So, when the system
        // tries to set the return register, we set the PC. You can see this behavior
        // in the HMDDwarfUnwindSetRegisterValue implemenation for that architecture. In the
        // case of ARM64, the register is real. So, we have to be extra careful to make sure
        // we update the PC here. Otherwise, when a DWARF unwind completes, it won't have
        // changed the PC to the right value.
        hmd_thread_state_set_lr(registers, value);
        hmd_thread_state_set_pc(registers, value);
        return true;
      default:
        break;
    }

    HMDDWLog("Unrecognized set register number %llu\n", num);

    return false;
}

uintptr_t HMDDwarfUnwindGetRegisterValue(const hmd_thread_state_t* registers, uint64_t num) {
  switch (num) {
    case HMD_DWARF_ARM64_X0:
      return registers->__ss.__x[0];
    case HMD_DWARF_ARM64_X1:
      return registers->__ss.__x[1];
    case HMD_DWARF_ARM64_X2:
      return registers->__ss.__x[2];
    case HMD_DWARF_ARM64_X3:
      return registers->__ss.__x[3];
    case HMD_DWARF_ARM64_X4:
      return registers->__ss.__x[4];
    case HMD_DWARF_ARM64_X5:
      return registers->__ss.__x[5];
    case HMD_DWARF_ARM64_X6:
      return registers->__ss.__x[6];
    case HMD_DWARF_ARM64_X7:
      return registers->__ss.__x[7];
    case HMD_DWARF_ARM64_X8:
      return registers->__ss.__x[8];
    case HMD_DWARF_ARM64_X9:
      return registers->__ss.__x[9];
    case HMD_DWARF_ARM64_X10:
      return registers->__ss.__x[10];
    case HMD_DWARF_ARM64_X11:
      return registers->__ss.__x[11];
    case HMD_DWARF_ARM64_X12:
      return registers->__ss.__x[12];
    case HMD_DWARF_ARM64_X13:
      return registers->__ss.__x[13];
    case HMD_DWARF_ARM64_X14:
      return registers->__ss.__x[14];
    case HMD_DWARF_ARM64_X15:
      return registers->__ss.__x[15];
    case HMD_DWARF_ARM64_X16:
      return registers->__ss.__x[16];
    case HMD_DWARF_ARM64_X17:
      return registers->__ss.__x[17];
    case HMD_DWARF_ARM64_X18:
      return registers->__ss.__x[18];
    case HMD_DWARF_ARM64_X19:
      return registers->__ss.__x[19];
    case HMD_DWARF_ARM64_X20:
      return registers->__ss.__x[20];
    case HMD_DWARF_ARM64_X21:
      return registers->__ss.__x[21];
    case HMD_DWARF_ARM64_X22:
      return registers->__ss.__x[22];
    case HMD_DWARF_ARM64_X23:
      return registers->__ss.__x[23];
    case HMD_DWARF_ARM64_X24:
      return registers->__ss.__x[24];
    case HMD_DWARF_ARM64_X25:
      return registers->__ss.__x[25];
    case HMD_DWARF_ARM64_X26:
      return registers->__ss.__x[26];
    case HMD_DWARF_ARM64_X27:
      return registers->__ss.__x[27];
    case HMD_DWARF_ARM64_X28:
      return registers->__ss.__x[28];
    case HMD_DWARF_ARM64_FP:
      return hmd_thread_state_get_fp(registers);
    case HMD_DWARF_ARM64_LR:
      return hmd_thread_state_get_lr(registers);
    case HMD_DWARF_ARM64_SP:
      return hmd_thread_state_get_sp(registers);
    default:
      break;
  }

  HMDDWLog("Error: Unrecognized get register number %llu\n", num);

  return 0;
}

#endif
