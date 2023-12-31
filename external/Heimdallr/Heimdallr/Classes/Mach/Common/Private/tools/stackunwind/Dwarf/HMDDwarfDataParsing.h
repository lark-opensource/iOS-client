//
//  HMDDwarfDataParsing.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#ifndef HMDDwarfDataParsing_h
#define HMDDwarfDataParsing_h

#import "HMDDwarfConfig.h"

#if HMD_USE_DWARF_UNWIND

#include <stdint.h>

#define HMDDWLog(...)

#define HMDDW_INVALID_ADDRESS (0xffffffffffffffff)

__BEGIN_DECLS

// basic data types
uint8_t HMDDWParseUint8AndAdvance(const void** cursor);
uint16_t HMDDWParseUint16AndAdvance(const void** cursor);
int16_t HMDDWParseInt16AndAdvance(const void** cursor);
uint32_t HMDDWParseUint32AndAdvance(const void** cursor);
int32_t HMDDWParseInt32AndAdvance(const void** cursor);
uint64_t HMDDWParseUint64AndAdvance(const void** cursor);
int64_t HMDDWParseInt64AndAdvance(const void** cursor);
uintptr_t HMDDWParsePointerAndAdvance(const void** cursor);
uint64_t HMDDWParseULEB128AndAdvance(const void** cursor);
int64_t HMDDWParseLEB128AndAdvance(const void** cursor);
const char* HMDDWParseStringAndAdvance(const void** cursor);

// FDE/CIE-specifc structures
uint64_t HMDDWParseRecordLengthAndAdvance(const void** cursor);
uintptr_t HMDDWParseAddressWithEncodingAndAdvance(const void** cursor, uint8_t encoding);

__END_DECLS

#endif

#endif /* HMDDwarfDataParsing_h */
