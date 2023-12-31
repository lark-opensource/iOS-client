//
//  HMDDwarfUnwind.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#ifndef HMDDwarfUnwind_h
#define HMDDwarfUnwind_h

#include <stdio.h>

#import "HMDDwarfConfig.h"

#if HMD_USE_DWARF_UNWIND

#include "HMDDwarfUnwindRegisters.h"
#include "HMDAsyncThreadState.h"

#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

#pragma mark Structures
typedef struct {
  uint32_t length;
  const void* data;
} HMDDWARFInstructions;

typedef struct {
  uint64_t length;
  uint8_t version;
  uintptr_t ehData;  // 8 bytes for 64-bit architectures, 4 bytes for 32
  const char* augmentation;
  uint8_t pointerEncoding;
  uint8_t lsdaEncoding;
  uint8_t personalityEncoding;
  uintptr_t personalityFunction;
  uint64_t codeAlignFactor;
  int64_t dataAlignFactor;
  uint64_t returnAddressRegister;  // is 64 bits enough for this value?
  bool signalFrame;

  HMDDWARFInstructions instructions;
} HMDDWARFCIERecord;

typedef struct {
  uint64_t length;
  uint64_t cieOffset;  // also an arch-specific size
  uintptr_t startAddress;
  uintptr_t rangeSize;

  HMDDWARFInstructions instructions;
} HMDDWARFFDERecord;

typedef struct {
  HMDDWARFCIERecord cie;
  HMDDWARFFDERecord fde;
} HMDDwarfCFIRecord;

typedef enum {
  HMDDwarfRegisterUnused = 0,
  HMDDwarfRegisterInCFA,
  HMDDwarfRegisterOffsetFromCFA,
  HMDDwarfRegisterInRegister,
  HMDDwarfRegisterAtExpression,
  HMDDwarfRegisterIsExpression
} HMDDwarfRegisterLocation;

typedef struct {
  HMDDwarfRegisterLocation location;
  uint64_t value;
} HMDDwarfRegister;

typedef struct {
  uint64_t cfaRegister;
  int64_t cfaRegisterOffset;
  const void* cfaExpression;
  uint32_t spArgSize;

  HMDDwarfRegister registers[HMD_DWARF_MAX_REGISTER_NUM + 1];
} HMDDwarfState;

__BEGIN_DECLS

#pragma mark - Parsing
bool HMDDwarfParseCIERecord(HMDDWARFCIERecord* cie, const void* ptr);
bool HMDDwarfParseFDERecord(HMDDWARFFDERecord* fdeRecord,
                               bool parseCIE,
                               HMDDWARFCIERecord* cieRecord,
                               const void* ptr);
bool HMDDwarfParseCFIFromFDERecord(HMDDwarfCFIRecord* record, const void* ptr);
bool HMDDwarfParseCFIFromFDERecordOffset(HMDDwarfCFIRecord* record,
                                            const void* ehFrame,
                                            uintptr_t fdeOffset);

#pragma mark - Properties
bool HMDDwarfCIEIsValid(HMDDWARFCIERecord* cie);
bool HMDDwarfCIEHasAugmentationData(HMDDWARFCIERecord* cie);

#pragma mark - Execution
bool HMDDwarfInstructionsEnumerate(HMDDWARFInstructions* instructions,
                                      HMDDWARFCIERecord* cieRecord,
                                      HMDDwarfState* state,
                                      intptr_t pcOffset);
bool HMDDwarfUnwindComputeRegisters(HMDDwarfCFIRecord* record,
                                       hmd_thread_state_t* registers);
bool HMDDwarfUnwindAssignRegisters(const HMDDwarfState* state,
                                      const hmd_thread_state_t* registers,
                                      uintptr_t cfaRegister,
                                      hmd_thread_state_t* outputRegisters);

#pragma mark - Register Operations
bool HMDDwarfCompareRegisters(const hmd_thread_state_t* a,
                                 const hmd_thread_state_t* b,
                                 uint64_t registerNum);

bool HMDDwarfGetCFA(HMDDwarfState* state,
                       const hmd_thread_state_t* registers,
                       uintptr_t* cfa);
uintptr_t HMDDwarfGetSavedRegister(const hmd_thread_state_t* registers,
                                      uintptr_t cfaRegister,
                                      HMDDwarfRegister dRegister);

__END_DECLS

#endif

#endif /* HMDDwarfUnwind_h */
