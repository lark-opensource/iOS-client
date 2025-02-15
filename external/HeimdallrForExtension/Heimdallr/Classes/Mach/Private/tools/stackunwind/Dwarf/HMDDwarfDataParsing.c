//
//  HMDDwarfDataParsing.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#include "HMDDwarfDataParsing.h"

#if HMD_USE_DWARF_UNWIND

#include "dwarf.h"

#include <string.h>

uint8_t HMDDWParseUint8AndAdvance(const void** cursor) {
  uint8_t tmp = **(uint8_t**)cursor;

  *cursor += sizeof(uint8_t);

  return tmp;
}

uint16_t HMDDWParseUint16AndAdvance(const void** cursor) {
  uint16_t tmp = **(uint16_t**)cursor;

  *cursor += sizeof(uint16_t);

  return tmp;
}

int16_t HMDDWParseInt16AndAdvance(const void** cursor) {
  int16_t tmp = **(int16_t**)cursor;

  *cursor += sizeof(int16_t);

  return tmp;
}

uint32_t HMDDWParseUint32AndAdvance(const void** cursor) {
  uint32_t tmp = **(uint32_t**)cursor;

  *cursor += sizeof(uint32_t);

  return tmp;
}

int32_t HMDDWParseInt32AndAdvance(const void** cursor) {
  int32_t tmp = **(int32_t**)cursor;

  *cursor += sizeof(int32_t);

  return tmp;
}

uint64_t HMDDWParseUint64AndAdvance(const void** cursor) {
  uint64_t tmp = **(uint64_t**)cursor;

  *cursor += sizeof(uint64_t);

  return tmp;
}

int64_t HMDDWParseInt64AndAdvance(const void** cursor) {
  int64_t tmp = **(int64_t**)cursor;

  *cursor += sizeof(int64_t);

  return tmp;
}

uintptr_t HMDDWParsePointerAndAdvance(const void** cursor) {
  uintptr_t tmp = **(uintptr_t**)cursor;

  *cursor += sizeof(uintptr_t);

  return tmp;
}

// Signed and Unsigned LEB128 decoding algorithms taken from Wikipedia -
// http://en.wikipedia.org/wiki/LEB128
uint64_t HMDDWParseULEB128AndAdvance(const void** cursor) {
  uint64_t result = 0;
  char shift = 0;

  for (int i = 0; i < sizeof(uint64_t); ++i) {
    char byte;

    byte = **(uint8_t**)cursor;

    *cursor += 1;

    result |= ((0x7F & byte) << shift);
    if ((0x80 & byte) == 0) {
      break;
    }

    shift += 7;
  }

  return result;
}

int64_t HMDDWParseLEB128AndAdvance(const void** cursor) {
  uint64_t result = 0;
  char shift = 0;
  char size = sizeof(int64_t) * 8;
  char byte = 0;

  for (int i = 0; i < sizeof(uint64_t); ++i) {
    byte = **(uint8_t**)cursor;

    *cursor += 1;

    result |= ((0x7F & byte) << shift);
    shift += 7;

    /* sign bit of byte is second high order bit (0x40) */
    if ((0x80 & byte) == 0) {
      break;
    }
  }

  if ((shift < size) && (0x40 & byte)) {
    // sign extend
    result |= -(1 << shift);
  }

  return result;
}

const char* HMDDWParseStringAndAdvance(const void** cursor) {
  const char* string;

  string = (const char*)(*cursor);

  // strlen doesn't include the null character, which we need to advance past
  *cursor += strlen(string) + 1;

  return string;
}

uint64_t HMDDWParseRecordLengthAndAdvance(const void** cursor) {
  uint64_t length;

  length = HMDDWParseUint32AndAdvance(cursor);
  if (length == HMD_DWARF_EXTENDED_LENGTH_FLAG) {
    length = HMDDWParseUint64AndAdvance(cursor);
  }

  return length;
}

uintptr_t HMDDWParseAddressWithEncodingAndAdvance(const void** cursor, uint8_t encoding) {
  if (encoding == HMD_DW_EH_PE_omit) {
    return 0;
  }

  if (!cursor) {
    return HMDDW_INVALID_ADDRESS;
  }

  if (!*cursor) {
    return HMDDW_INVALID_ADDRESS;
  }

  intptr_t inputAddr = (intptr_t)*cursor;
  intptr_t addr;

  switch (encoding & HMD_DW_EH_PE_VALUE_MASK) {
    case HMD_DW_EH_PE_ptr:
      // 32 or 64 bits
      addr = HMDDWParsePointerAndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_uleb128:
      addr = (intptr_t)HMDDWParseULEB128AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_udata2:
      addr = HMDDWParseUint16AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_udata4:
      addr = HMDDWParseUint32AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_udata8:
      addr = (intptr_t)HMDDWParseUint64AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_sleb128:
      addr = (intptr_t)HMDDWParseLEB128AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_sdata2:
      addr = HMDDWParseInt16AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_sdata4:
      addr = HMDDWParseInt32AndAdvance(cursor);
      break;
    case HMD_DW_EH_PE_sdata8:
      addr = (intptr_t)HMDDWParseInt64AndAdvance(cursor);
      break;
    default:
      HMDDWLog("Unhandled: encoding 0x%02x\n", encoding);
      return HMDDW_INVALID_ADDRESS;
  }

  // and now apply the relative offset
  switch (encoding & HMD_DW_EH_PE_RELATIVE_OFFSET_MASK) {
    case HMD_DW_EH_PE_absptr:
      break;
    case HMD_DW_EH_PE_pcrel:
      addr += inputAddr;
      break;
    default:
      HMDDWLog("Unhandled: relative encoding 0x%02x\n", encoding);
      return HMDDW_INVALID_ADDRESS;
  }

  // Here's a crazy one. It seems this encoding means you actually look up
  // the value of the address using the result address itself
  if (encoding & HMD_DW_EH_PE_indirect) {
    if (!addr) {
      return HMDDW_INVALID_ADDRESS;
    }

    addr = *(uintptr_t*)addr;
  }

  return addr;
}

#endif
