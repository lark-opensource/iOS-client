//
//  HMDDwarfUnwind.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#include "HMDDwarfUnwind.h"

#if HMD_USE_DWARF_UNWIND

#include "HMDDwarfDataParsing.h"
#include "HMDDwarfExpressionMachine.h"
#include "dwarf.h"
#include "hmd_memory.h"
#include <string.h>

#define HMD_DWARF_EXPRESSION_STACK_SIZE (100)

#pragma mark Prototypes
static bool HMDDwarfParseAndProcessAugmentation(HMDDWARFCIERecord* record, const void** ptr);

#pragma mark - Record Parsing
bool HMDDwarfParseCIERecord(HMDDWARFCIERecord* cie, const void* ptr) {
  if (!cie || !ptr) {
    return false;
  }

  memset(cie, 0, sizeof(HMDDWARFCIERecord));

  cie->length = HMDDWParseRecordLengthAndAdvance(&ptr);
  if (cie->length == 0) {
    HMDDWLog("Error: CIE length invalid\n");
    return false;
  }

  // the length does not include the length field(s) themselves
  const void* endAddress = ptr + cie->length;

  if (HMDDWParseUint32AndAdvance(&ptr) != HMD_DWARF_CIE_ID_CIE_FLAG) {
    HMDDWLog("Error: CIE flag not found\n");
  }

  cie->version = HMDDWParseUint8AndAdvance(&ptr);
  if (cie->version != 1 && cie->version != 3) {
    HMDDWLog("Error: CIE version %u unsupported\n", cie->version);
  }

  cie->pointerEncoding = HMD_DW_EH_PE_absptr;
  cie->lsdaEncoding = HMD_DW_EH_PE_absptr;

  cie->augmentation = HMDDWParseStringAndAdvance(&ptr);
  cie->codeAlignFactor = HMDDWParseULEB128AndAdvance(&ptr);
  cie->dataAlignFactor = HMDDWParseLEB128AndAdvance(&ptr);

  switch (cie->version) {
    case 1:
      cie->returnAddressRegister = HMDDWParseUint8AndAdvance(&ptr);
      break;
    case 3:
      cie->returnAddressRegister = HMDDWParseULEB128AndAdvance(&ptr);
      break;
    default:
      HMDDWLog("Error: CIE version %u unsupported\n", cie->version);
      return false;
  }

  if (!HMDDwarfParseAndProcessAugmentation(cie, &ptr)) {
    return false;
  }

  cie->instructions.data = ptr;
  cie->instructions.length = (uint32_t)(endAddress - ptr);

  return true;
}

static bool HMDDwarfParseAndProcessAugmentation(HMDDWARFCIERecord* record, const void** ptr) {
  if (!record || !ptr) {
    return false;
  }

  if (!record->augmentation) {
    return false;
  }

  if (record->augmentation[0] == 0) {
    return true;
  }

  if (record->augmentation[0] != 'z') {
    HMDDWLog("Error: Unimplemented: augmentation string %s\n", record->augmentation);
    return false;
  }

  size_t stringLength = strlen(record->augmentation);

  uint64_t dataLength = HMDDWParseULEB128AndAdvance(ptr);
  const void* ending = *ptr + dataLength;

  // start at 1 because we know the first character is a 'z'
  for (size_t i = 1; i < stringLength; ++i) {
    switch (record->augmentation[i]) {
      case 'L':
        // There is an LSDA pointer encoding present.  The actual address of the LSDA
        // is in the FDE
        record->lsdaEncoding = HMDDWParseUint8AndAdvance(ptr);
        break;
      case 'R':
        // There is a pointer encoding present, used for all addresses in an FDE.
        record->pointerEncoding = HMDDWParseUint8AndAdvance(ptr);
        break;
      case 'P':
        // Two arguments.  A pointer encoding, and a pointer to a personality function encoded
        // with that value.
        record->personalityEncoding = HMDDWParseUint8AndAdvance(ptr);
        record->personalityFunction =
            HMDDWParseAddressWithEncodingAndAdvance(ptr, record->personalityEncoding);
        if (record->personalityFunction == HMDDW_INVALID_ADDRESS) {
          HMDDWLog("Error: Found an invalid start address\n");
          return false;
        }
        break;
      case 'S':
        record->signalFrame = true;
        break;
      default:
        HMDDWLog("Error: Unhandled augmentation string entry %c\n", record->augmentation[i]);
        return false;
    }

    // small sanity check
    if (*ptr > ending) {
      return false;
    }
  }

  return true;
}

bool HMDDwarfParseFDERecord(HMDDWARFFDERecord* fdeRecord,
                               bool parseCIE,
                               HMDDWARFCIERecord* cieRecord,
                               const void* ptr) {
  if (!fdeRecord || !cieRecord || !ptr) {
    return false;
  }

  fdeRecord->length = HMDDWParseRecordLengthAndAdvance(&ptr);
  if (fdeRecord->length == 0) {
    HMDDWLog("Error: FDE has zero length\n");
    return false;
  }

  // length does not include length field
  const void* endAddress = ptr + fdeRecord->length;

  // According to the spec, this is 32/64 bit value, but libunwind always
  // parses this as a 32bit value.
  fdeRecord->cieOffset = HMDDWParseUint32AndAdvance(&ptr);
  if (fdeRecord->cieOffset == 0) {
    HMDDWLog("Error: CIE offset invalid\n");
    return false;
  }

  if (parseCIE) {
    // The CIE offset is really weird. It appears to be an offset from the
    // beginning of its field. This isn't what the documentation says, but it is
    // a little ambigious. This is what DwarfParser.hpp does.
    // Note that we have to back up one sizeof(uint32_t), because we've advanced
    // by parsing the offset
    const void* ciePointer = ptr - fdeRecord->cieOffset - sizeof(uint32_t);
    if (!HMDDwarfParseCIERecord(cieRecord, ciePointer)) {
      HMDDWLog("Error: Unable to parse CIE record\n");
      return false;
    }
  }

  if (!HMDDwarfCIEIsValid(cieRecord)) {
    HMDDWLog("Error: CIE invalid\n");
    return false;
  }

  // the next field depends on the pointer encoding style used
  fdeRecord->startAddress =
      HMDDWParseAddressWithEncodingAndAdvance(&ptr, cieRecord->pointerEncoding);
  if (fdeRecord->startAddress == HMDDW_INVALID_ADDRESS) {
    HMDDWLog("Error: Found an invalid start address\n");
    return false;
  }

  // Here's something weird too. The range is encoded as a "special" address, where only the value
  // is used, regardless of other pointer-encoding schemes.
  fdeRecord->rangeSize = HMDDWParseAddressWithEncodingAndAdvance(
      &ptr, cieRecord->pointerEncoding & HMD_DW_EH_PE_VALUE_MASK);
  if (fdeRecord->rangeSize == HMDDW_INVALID_ADDRESS) {
    HMDDWLog("Error: Found an invalid address range\n");
    return false;
  }

  // Just skip over the section for now. The data here is only needed for personality functions,
  // which we don't need
  if (HMDDwarfCIEHasAugmentationData(cieRecord)) {
    uintptr_t augmentationLength = (uintptr_t)HMDDWParseULEB128AndAdvance(&ptr);

    ptr += augmentationLength;
  }

  fdeRecord->instructions.data = ptr;
  fdeRecord->instructions.length = (uint32_t)(endAddress - ptr);

  return true;
}

bool HMDDwarfParseCFIFromFDERecord(HMDDwarfCFIRecord* record, const void* ptr) {
  if (!record || !ptr) {
    return false;
  }

  return HMDDwarfParseFDERecord(&record->fde, true, &record->cie, ptr);
}

bool HMDDwarfParseCFIFromFDERecordOffset(HMDDwarfCFIRecord* record,
                                            const void* ehFrame,
                                            uintptr_t fdeOffset) {
  if (!record || !ehFrame || (fdeOffset == 0)) {
    return false;
  }

  const void* ptr = ehFrame + fdeOffset;

  return HMDDwarfParseCFIFromFDERecord(record, ptr);
}

#pragma mark - Properties
bool HMDDwarfCIEIsValid(HMDDWARFCIERecord* cie) {
  if (!cie) {
    return false;
  }

  if (cie->length == 0) {
    return false;
  }

  if (cie->version != 1 && cie->version != 3) {
    return false;
  }

  return true;
}

bool HMDDwarfCIEHasAugmentationData(HMDDWARFCIERecord* cie) {
  if (!cie) {
    return false;
  }

  if (!cie->augmentation) {
    return false;
  }

  return cie->augmentation[0] == 'z';
}

#pragma mark - Instructions

static bool HMDDwarfParseAndExecute_set_loc(const void** cursor,
                                               HMDDWARFCIERecord* cieRecord,
                                               intptr_t* codeOffset) {
  uintptr_t operand = HMDDWParseAddressWithEncodingAndAdvance(cursor, cieRecord->pointerEncoding);

  *codeOffset = operand;

  HMDDWLog("DW_CFA_set_loc %lu\n", operand);

  return true;
}

static bool HMDDwarfParseAndExecute_advance_loc1(const void** cursor,
                                                    HMDDWARFCIERecord* cieRecord,
                                                    intptr_t* codeOffset) {
  int64_t offset = HMDDWParseUint8AndAdvance(cursor) * cieRecord->codeAlignFactor;

  *codeOffset += offset;

  HMDDWLog("DW_CFA_advance_loc1 %lld\n", offset);

  return true;
}

static bool HMDDwarfParseAndExecute_advance_loc2(const void** cursor,
                                                    HMDDWARFCIERecord* cieRecord,
                                                    intptr_t* codeOffset) {
  int64_t offset = HMDDWParseUint16AndAdvance(cursor) * cieRecord->codeAlignFactor;

  *codeOffset += offset;

  HMDDWLog("DW_CFA_advance_loc2 %lld\n", offset);

  return true;
}

static bool HMDDwarfParseAndExecute_advance_loc4(const void** cursor,
                                                    HMDDWARFCIERecord* cieRecord,
                                                    intptr_t* codeOffset) {
  int64_t offset = HMDDWParseUint32AndAdvance(cursor) * cieRecord->codeAlignFactor;

  *codeOffset += offset;

  HMDDWLog("DW_CFA_advance_loc4 %lld\n", offset);

  return true;
}

static bool HMDDwarfParseAndExecute_def_cfa(const void** cursor,
                                               HMDDWARFCIERecord* cieRecord,
                                               HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_def_cfa register number\n");
    return false;
  }

  int64_t offset = HMDDWParseULEB128AndAdvance(cursor);

  state->cfaRegister = regNum;
  state->cfaRegisterOffset = offset;

  HMDDWLog("DW_CFA_def_cfa %llu, %lld\n", regNum, offset);

  return true;
}

static bool HMDDwarfParseAndExecute_def_cfa_register(const void** cursor,
                                                        HMDDWARFCIERecord* cieRecord,
                                                        HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_def_cfa_register register number\n");
    return false;
  }

  state->cfaRegister = regNum;

  HMDDWLog("DW_CFA_def_cfa_register %llu\n", regNum);

  return true;
}

static bool HMDDwarfParseAndExecute_def_cfa_offset(const void** cursor,
                                                      HMDDWARFCIERecord* cieRecord,
                                                      HMDDwarfState* state) {
  uint64_t offset = HMDDWParseULEB128AndAdvance(cursor);

  state->cfaRegisterOffset = offset;

  HMDDWLog("DW_CFA_def_cfa_offset %lld\n", offset);

  return true;
}

static bool HMDDwarfParseAndExecute_same_value(const void** cursor,
                                                  HMDDWARFCIERecord* cieRecord,
                                                  HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_same_value register number\n");
    return false;
  }

  state->registers[regNum].location = HMDDwarfRegisterUnused;

  HMDDWLog("DW_CFA_same_value %llu\n", regNum);

  return true;
}

static bool HMDDwarfParseAndExecute_register(const void** cursor,
                                                HMDDWARFCIERecord* cieRecord,
                                                HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_register number\n");
    return false;
  }

  uint64_t regValue = HMDDWParseULEB128AndAdvance(cursor);

  if (regValue > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_register value\n");
    return false;
  }

  state->registers[regNum].location = HMDDwarfRegisterInRegister;
  state->registers[regNum].value = regValue;

  HMDDWLog("DW_CFA_register %llu %llu\n", regNum, regValue);

  return true;
}

static bool HMDDwarfParseAndExecute_expression(const void** cursor,
                                                  HMDDWARFCIERecord* cieRecord,
                                                  HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_expression register number\n");
    return false;
  }

  state->registers[regNum].location = HMDDwarfRegisterAtExpression;
  state->registers[regNum].value = (uintptr_t)*cursor;

  // read the length of the expression, and advance past it
  uint64_t length = HMDDWParseULEB128AndAdvance(cursor);
  *cursor += length;

  HMDDWLog("DW_CFA_expression %llu %llu\n", regNum, length);

  return true;
}

static bool HMDDwarfParseAndExecute_val_expression(const void** cursor,
                                                      HMDDWARFCIERecord* cieRecord,
                                                      HMDDwarfState* state) {
  uint64_t regNum = HMDDWParseULEB128AndAdvance(cursor);

  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_val_expression register number\n");
    return false;
  }

  state->registers[regNum].location = HMDDwarfRegisterIsExpression;
  state->registers[regNum].value = (uintptr_t)*cursor;

  // read the length of the expression, and advance past it
  uint64_t length = HMDDWParseULEB128AndAdvance(cursor);
  *cursor += length;

  HMDDWLog("DW_CFA_val_expression %llu %llu\n", regNum, length);

  return true;
}

static bool HMDDwarfParseAndExecute_def_cfa_expression(const void** cursor,
                                                          HMDDWARFCIERecord* cieRecord,
                                                          HMDDwarfState* state) {
  state->cfaRegister = HMD_DWARF_INVALID_REGISTER_NUM;
  state->cfaExpression = *cursor;

  // read the length of the expression, and advance past it
  uint64_t length = HMDDWParseULEB128AndAdvance(cursor);
  *cursor += length;

  HMDDWLog("DW_CFA_def_cfa_expression %llu\n", length);

  return true;
}

static bool HMDDwarfParseAndExecute_offset(const void** cursor,
                                              HMDDWARFCIERecord* cieRecord,
                                              HMDDwarfState* state,
                                              uint8_t regNum) {
  if (regNum > HMD_DWARF_MAX_REGISTER_NUM) {
    HMDDWLog("Error: Found an invalid DW_CFA_offset register number\n");
    return false;
  }

  int64_t offset = HMDDWParseULEB128AndAdvance(cursor) * cieRecord->dataAlignFactor;

  state->registers[regNum].location = HMDDwarfRegisterInCFA;
  state->registers[regNum].value = offset;

  HMDDWLog("DW_CFA_offset %u, %lld\n", regNum, offset);

  return true;
}

static bool HMDDwarfParseAndExecute_advance_loc(const void** cursor,
                                                   HMDDWARFCIERecord* cieRecord,
                                                   HMDDwarfState* state,
                                                   uint8_t delta,
                                                   intptr_t* codeOffset) {
  if (!HMD_IS_VALID_PTR(codeOffset) || !HMD_IS_VALID_PTR(cieRecord)) {
    HMDDWLog("Error: invalid inputs\n");
    return false;
  }

  *codeOffset = delta * (intptr_t)cieRecord->codeAlignFactor;

  HMDDWLog("DW_CFA_advance_loc %u\n", delta);

  return true;
}

static bool HMDDwarfParseAndExecuteInstructionWithOperand(const void** cursor,
                                                             uint8_t instruction,
                                                             HMDDWARFCIERecord* cieRecord,
                                                             HMDDwarfState* state,
                                                             intptr_t* codeOffset) {
  uint8_t operand = instruction & HMD_DW_CFA_OPERAND_MASK;
  bool success = false;

  switch (instruction & HMD_DW_CFA_OPCODE_MASK) {
    case HMD_DW_CFA_offset:
      success = HMDDwarfParseAndExecute_offset(cursor, cieRecord, state, operand);
      break;
    case HMD_DW_CFA_advance_loc:
      success =
          HMDDwarfParseAndExecute_advance_loc(cursor, cieRecord, state, operand, codeOffset);
      break;
    case HMD_DW_CFA_restore:
      HMDDWLog("Error: Unimplemented DWARF instruction with operand 0x%x\n", instruction);
      break;
    default:
      HMDDWLog("Error: Unrecognized DWARF instruction 0x%x\n", instruction);
      break;
  }

  return success;
}

#pragma mark - Expressions
static bool HMDDwarfEvalulateExpression(const void* cursor,
                                           const hmd_thread_state_t* registers,
                                           intptr_t stackValue,
                                           intptr_t* result) {
  HMDDWLog("starting at %p with initial value %lx\n", cursor, stackValue);

  if (!HMD_IS_VALID_PTR(cursor) || !HMD_IS_VALID_PTR(result)) {
    HMDDWLog("Error: inputs invalid\n");
    return false;
  }

  HMDDwarfExpressionMachine machine;

  if (!HMDDwarfExpressionMachineInit(&machine, cursor, registers, stackValue)) {
    HMDDWLog("Error: unable to init DWARF expression machine\n");
    return false;
  }

  if (!HMDDwarfExpressionMachinePrepareForExecution(&machine)) {
    HMDDWLog("Error: unable to prepare for execution\n");
    return false;
  }

  while (!HMDDwarfExpressionMachineIsFinished(&machine)) {
    if (!HMDDwarfExpressionMachineExecuteNextOpcode(&machine)) {
      HMDDWLog("Error: failed to execute DWARF machine opcode\n");
      return false;
    }
  }

  if (!HMDDwarfExpressionMachineGetResult(&machine, result)) {
    HMDDWLog("Error: failed to get DWARF expression result\n");
    return false;
  }

  HMDDWLog("successfully computed expression result\n");

  return true;
}

#pragma mark - Execution
bool HMDDwarfInstructionsEnumerate(HMDDWARFInstructions* instructions,
                                      HMDDWARFCIERecord* cieRecord,
                                      HMDDwarfState* state,
                                      intptr_t pcOffset) {
  if (!instructions || !cieRecord || !state) {
    HMDDWLog("Error: inputs invalid\n");
    return false;
  }

  // This is a little bit of state that can't be put into the state structure, because
  // it is possible for instructions to push/pop state that does not affect this value.
  intptr_t codeOffset = 0;

  const void* cursor = instructions->data;
  const void* endAddress = cursor + instructions->length;

  HMDDWLog("Running instructions from %p to %p\n", cursor, endAddress);

  // parse the instructions, as long as:
  // - our data pointer is still in range
  // - the pc offset is within the range of instructions that apply

  while ((cursor < endAddress) && (codeOffset < pcOffset)) {
    uint8_t instruction = HMDDWParseUint8AndAdvance(&cursor);
    bool success = false;

    switch (instruction) {
      case HMD_DW_CFA_nop:
        HMDDWLog("DW_CFA_nop\n");
        continue;
      case HMD_DW_CFA_set_loc:
        success = HMDDwarfParseAndExecute_set_loc(&cursor, cieRecord, &codeOffset);
        break;
      case HMD_DW_CFA_advance_loc1:
        success = HMDDwarfParseAndExecute_advance_loc1(&cursor, cieRecord, &codeOffset);
        break;
      case HMD_DW_CFA_advance_loc2:
        success = HMDDwarfParseAndExecute_advance_loc2(&cursor, cieRecord, &codeOffset);
        break;
      case HMD_DW_CFA_advance_loc4:
        success = HMDDwarfParseAndExecute_advance_loc4(&cursor, cieRecord, &codeOffset);
        break;
      case HMD_DW_CFA_def_cfa:
        success = HMDDwarfParseAndExecute_def_cfa(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_def_cfa_register:
        success = HMDDwarfParseAndExecute_def_cfa_register(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_def_cfa_offset:
        success = HMDDwarfParseAndExecute_def_cfa_offset(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_same_value:
        success = HMDDwarfParseAndExecute_same_value(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_register:
        success = HMDDwarfParseAndExecute_register(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_def_cfa_expression:
        success = HMDDwarfParseAndExecute_def_cfa_expression(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_expression:
        success = HMDDwarfParseAndExecute_expression(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_val_expression:
        success = HMDDwarfParseAndExecute_val_expression(&cursor, cieRecord, state);
        break;
      case HMD_DW_CFA_offset_extended:
      case HMD_DW_CFA_restore_extended:
      case HMD_DW_CFA_undefined:
      case HMD_DW_CFA_remember_state:
      case HMD_DW_CFA_restore_state:
      case HMD_DW_CFA_offset_extended_sf:
      case HMD_DW_CFA_def_cfa_sf:
      case HMD_DW_CFA_def_cfa_offset_sf:
      case HMD_DW_CFA_val_offset:
      case HMD_DW_CFA_val_offset_sf:
      case HMD_DW_CFA_GNU_window_save:
      case HMD_DW_CFA_GNU_args_size:
      case HMD_DW_CFA_GNU_negative_offset_extended:
        HMDDWLog("Error: Unimplemented DWARF instruction 0x%x\n", instruction);
        return false;
      default:
        success = HMDDwarfParseAndExecuteInstructionWithOperand(&cursor, instruction, cieRecord,
                                                                   state, &codeOffset);
        break;
    }

    if (!success) {
      HMDDWLog("Error: Failed to execute dwarf instruction 0x%x\n", instruction);
      return false;
    }
  }

  return true;
}

bool HMDDwarfUnwindComputeRegisters(HMDDwarfCFIRecord* record,
                                       hmd_thread_state_t* registers) {
  if (!record || !registers) {
    return false;
  }

  // We need to run the dwarf instructions to compute our register values.
  // - initialize state
  // - run the CIE instructions
  // - run the FDE instructions
  // - grab the values

  HMDDwarfState state;

  memset(&state, 0, sizeof(HMDDwarfState));

  // We need to run all the instructions in the CIE record. So, pass in a large value for the pc
  // offset so we don't stop early.
  if (!HMDDwarfInstructionsEnumerate(&record->cie.instructions, &record->cie, &state,
                                        INTPTR_MAX)) {
    HMDDWLog("Error: Unable to run CIE instructions\n");
    return false;
  }

  intptr_t pcOffset = hmd_thread_state_get_pc(registers) - record->fde.startAddress;
  if (pcOffset < 0) {
    HMDDWLog("Error: The FDE pcOffset value cannot be negative\n");
    return false;
  }

  if (!HMDDwarfInstructionsEnumerate(&record->fde.instructions, &record->cie, &state,
                                        pcOffset)) {
    HMDDWLog("Error: Unable to run FDE instructions\n");
    return false;
  }

  uintptr_t cfaRegister = 0;

  if (!HMDDwarfGetCFA(&state, registers, &cfaRegister)) {
    HMDDWLog("Error: failed to get CFA\n");
    return false;
  }

  if (!HMDDwarfUnwindAssignRegisters(&state, registers, cfaRegister, registers)) {
    //("Error: Unable to assign DWARF registers\n");
    return false;
  }

  return true;
}

bool HMDDwarfUnwindAssignRegisters(const HMDDwarfState* state,
                                      const hmd_thread_state_t* registers,
                                      uintptr_t cfaRegister,
                                      hmd_thread_state_t* outputRegisters) {
  if (!HMD_IS_VALID_PTR(state) || !HMD_IS_VALID_PTR(registers)) {
    //("Error: input invalid\n");
    return false;
  }

  // make a copy, which we'll be changing
  hmd_thread_state_t newThreadState = *registers;

  // loop through all the registers, so we can set their values
  for (size_t i = 0; i <= HMD_DWARF_MAX_REGISTER_NUM; ++i) {
    if (state->registers[i].location == HMDDwarfRegisterUnused) {
      continue;
    }

    const uintptr_t value =
        HMDDwarfGetSavedRegister(registers, cfaRegister, state->registers[i]);

    if (!HMDDwarfUnwindSetRegisterValue(&newThreadState, i, value)) {
      HMDDWLog("Error: Unable to restore register value\n");
      return false;
    }
  }

  if (!HMDDwarfUnwindSetRegisterValue(&newThreadState, HMD_DWARF_REG_SP, cfaRegister)) {
    HMDDWLog("Error: Unable to restore SP value\n");
    return false;
  }

  // sanity-check that things have changed
  if (HMDDwarfCompareRegisters(registers, &newThreadState, HMD_DWARF_REG_SP)) {
    HMDDWLog("Error: Stack pointer hasn't changed\n");
    return false;
  }

  if (HMDDwarfCompareRegisters(registers, &newThreadState, HMD_DWARF_REG_RETURN)) {
    HMDDWLog("Error: PC hasn't changed\n");
    return false;
  }

  // set our new value
  *outputRegisters = newThreadState;

  return true;
}

#pragma mark - Register Operations
bool HMDDwarfCompareRegisters(const hmd_thread_state_t* a,
                                 const hmd_thread_state_t* b,
                                 uint64_t registerNum) {
  return HMDDwarfUnwindGetRegisterValue(a, registerNum) ==
         HMDDwarfUnwindGetRegisterValue(b, registerNum);
}

bool HMDDwarfGetCFA(HMDDwarfState* state,
                       const hmd_thread_state_t* registers,
                       uintptr_t* cfa) {
  if (!HMD_IS_VALID_PTR(state) || !HMD_IS_VALID_PTR(registers) ||
      !HMD_IS_VALID_PTR(cfa)) {
    HMDDWLog("Error: invalid input\n");
    return false;
  }

  if (state->cfaExpression) {
    if (!HMDDwarfEvalulateExpression(state->cfaExpression, registers, 0, (intptr_t*)cfa)) {
      HMDDWLog("Error: failed to compute CFA expression\n");
      return false;
    }

    return true;
  }

  // libunwind checks that cfaRegister is not zero. This seems like a potential bug - why couldn't
  // it be zero?

  *cfa = HMDDwarfUnwindGetRegisterValue(registers, state->cfaRegister) +
         (uintptr_t)state->cfaRegisterOffset;

  return true;
}

uintptr_t HMDDwarfGetSavedRegister(const hmd_thread_state_t* registers,
                                      uintptr_t cfaRegister,
                                      HMDDwarfRegister dRegister) {
  intptr_t result = 0;

  HMDDWLog("Getting register %x\n", dRegister.location);

  switch (dRegister.location) {
    case HMDDwarfRegisterInCFA: {
      const uintptr_t address = cfaRegister + (uintptr_t)dRegister.value;

      if (hmd_async_read_memory(address, &result, sizeof(result)) != HMD_ESUCCESS) {
        HMDDWLog("Error: Unable to read CFA value\n");
        return 0;
      }
    }
      return result;
    case HMDDwarfRegisterInRegister:
      return HMDDwarfUnwindGetRegisterValue(registers, dRegister.value);
    case HMDDwarfRegisterOffsetFromCFA:
      HMDDWLog("Error: OffsetFromCFA unhandled\n");
      break;
    case HMDDwarfRegisterAtExpression:
      if (!HMDDwarfEvalulateExpression((void*)dRegister.value, registers, cfaRegister,
                                          &result)) {
        HMDDWLog("Error: unable to evaluate expression\n");
        return 0;
      }

      if (hmd_async_read_memory(result, &result, sizeof(result)) != HMD_ESUCCESS) {
        HMDDWLog("Error: Unable to read memory computed from expression\n");
        return 0;
      }

      return result;
    case HMDDwarfRegisterIsExpression:
      if (!HMDDwarfEvalulateExpression((void*)dRegister.value, registers, cfaRegister,
                                          &result)) {
        HMDDWLog("Error: unable to evaluate expression\n");
        return 0;
      }

      return result;
    default:
      HMDDWLog("Error: Unrecognized register save location 0x%x\n", dRegister.location);
      break;
  }

  return 0;
}

#endif
