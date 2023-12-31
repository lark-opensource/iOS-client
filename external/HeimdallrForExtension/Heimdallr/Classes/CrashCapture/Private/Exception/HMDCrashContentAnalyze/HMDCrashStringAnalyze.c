//
//  HMDCrashStringAnalyze.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashStringAnalyze.h"
#include "HMDCrashContentAnalyzeBase.h"
#include "HMDCrashFileBuffer.h"
#include "hmd_objc_apple.h"
#include "HMDObjcRuntime.h"
#include "hmd_memory.h"

static int hmd_taggedStringLength(void* object) {
    uintptr_t payload = hmd_get_tagged_payload(object);
    return (int)(payload & 0xf);
}

static int hmd_extractTaggedNSString(const void *object, char *buffer, int maxByteCount) {
    int length = hmd_taggedStringLength((void *)object);
    int copyLength = ((length + 1) > maxByteCount) ? (maxByteCount - 1) : length;
    uintptr_t payload = hmd_get_tagged_payload((void *)object);
    uintptr_t value = payload >> 4;
    static char* alphabet = "eilotrm.apdnsIc ufkMShjTRxgC4013bDNvwyUL2O856P-B79AFKEWV_zGJ/HYX";
    if(length <=7) {
        for(int i = 0; i < copyLength; i++) {
            // ASCII case, limit to bottom 7 bits just in case
            buffer[i] = (char)(value & 0x7f);
            value >>= 8;
        }
    } else if(length <= 9) {
        for(int i = 0; i < copyLength; i++) {
            uintptr_t index = (value >> ((length - 1 - i) * 6)) & 0x3f;
            buffer[i] = alphabet[index];
        }
    } else if(length <= 11) {
        for(int i = 0; i < copyLength; i++) {
            uintptr_t index = (value >> ((length - 1 - i) * 5)) & 0x1f;
            buffer[i] = alphabet[index];
        }
    }
    else {
        buffer[0] = 0;
    }
    buffer[length] = 0;

    return length;
}

int hmd_stringLength(const void* const stringPtr) {
    HMDCrashObjectInfo info = {0};
    void *ptr = (void *)stringPtr;
    if (!HMDCrashGetObjectInfo(ptr, &info)) {
        return 0;
    }
    
    if (info.is_tagpointer && (hmd_get_tagged_slot(ptr) == HMD_TAG_NSString)) {
        return hmd_taggedStringLength(ptr);
    }
    
    struct HMDString string = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)stringPtr, &string, sizeof(struct HMDString)) != HMD_ESUCCESS) {
        return 0;
    }

    if (HMDStrHasExplicitLength(&string)) {
        if (HMDStrIsInline(&string)) {
            return (int)string.variants.inline1.length;
        } else {
            return (int)string.variants.notInlineImmutable1.length;
        }
    } else {
        return *((uint8_t *)HMDStrContents(&string));
    }
}

static inline const char* hmd_stringStart(const struct HMDString* str) {
    return (const char*)HMDStrContents(str) + (HMDStrHasLengthByte(str) ? 1 : 0);
}

#define kUTF16_LeadSurrogateStart       0xd800u
#define kUTF16_LeadSurrogateEnd         0xdbffu
#define kUTF16_TailSurrogateStart       0xdc00u
#define kUTF16_TailSurrogateEnd         0xdfffu
#define kUTF16_FirstSupplementaryPlane  0x10000u

static int hmd_copyAndConvertUTF16StringToUTF8(const void* const src, void* const dst, int charCount, int maxByteCount) {
    const uint16_t* pSrc = src;
    uint8_t* pDst = dst;
    const uint8_t* const pDstEnd = pDst + maxByteCount - 1; // Leave room for null termination.
    for(int charsRemaining = charCount; charsRemaining > 0 && pDst < pDstEnd; charsRemaining--) {
        // Decode UTF-16
        uint32_t character = 0;
        uint16_t leadSurrogate = *pSrc++;
        likely_if(leadSurrogate < kUTF16_LeadSurrogateStart || leadSurrogate > kUTF16_TailSurrogateEnd) {
            character = leadSurrogate;
        } else if(leadSurrogate > kUTF16_LeadSurrogateEnd) {
            // Inverted surrogate
            *((uint8_t*)dst) = 0;
            return 0;
        } else {
            uint16_t tailSurrogate = *pSrc++;
            if(tailSurrogate < kUTF16_TailSurrogateStart || tailSurrogate > kUTF16_TailSurrogateEnd) {
                // Invalid tail surrogate
                *((uint8_t*)dst) = 0;
                return 0;
            }
            character = ((leadSurrogate - kUTF16_LeadSurrogateStart) << 10) + (tailSurrogate - kUTF16_TailSurrogateStart);
            character += kUTF16_FirstSupplementaryPlane;
            charsRemaining--;
        }
        
        // Encode UTF-8
        likely_if(character <= 0x7f) {
            *pDst++ = (uint8_t)character;
        }
        else if(character <= 0x7ff) {
            if(pDstEnd - pDst >= 2) {
                *pDst++ = (uint8_t)(0xc0 | (character >> 6));
                *pDst++ = (uint8_t)(0x80 | (character & 0x3f));
            } else {
                break;
            }
        }
        else if(character <= 0xffff) {
            if(pDstEnd - pDst >= 3) {
                *pDst++ = (uint8_t)(0xe0 | (character >> 12));
                *pDst++ = (uint8_t)(0x80 | ((character >> 6) & 0x3f));
                *pDst++ = (uint8_t)(0x80 | (character & 0x3f));
            } else {
                break;
            }
        }
        // RFC3629 restricts UTF-8 to end at 0x10ffff.
        else if(character <= 0x10ffff) {
            if(pDstEnd - pDst >= 4) {
                *pDst++ = (uint8_t)(0xf0 | (character >> 18));
                *pDst++ = (uint8_t)(0x80 | ((character >> 12) & 0x3f));
                *pDst++ = (uint8_t)(0x80 | ((character >> 6) & 0x3f));
                *pDst++ = (uint8_t)(0x80 | (character & 0x3f));
            } else {
                break;
            }
        } else {
            // Invalid unicode.
            *((uint8_t*)dst) = 0;
            return 0;
        }
    }
    
    // Null terminate and return.
    *pDst = 0;
    return (int)(pDst - (uint8_t*)dst);
}

static int hmd_copy8BitString(const void* const src, void* const dst, int charCount, int maxByteCount) {
    unlikely_if(maxByteCount == 0) {
        return 0;
    }
    
    unlikely_if(charCount == 0) {
        *((uint8_t*)dst) = 0;
        return 0;
    }

    unlikely_if(charCount >= maxByteCount) {
        charCount = maxByteCount - 1;
    }
    
    unlikely_if(hmd_async_read_memory((hmd_vm_address_t)src, dst, charCount) != HMD_ESUCCESS) {
        *((uint8_t*)dst) = 0;
        return 0;
    }
    uint8_t* charDst = dst;
    charDst[charCount] = 0;
    return charCount;
}

static int hmd_copyStringContent(HMDCrashObjectInfo *info, char* dst, int maxByteCount) {
    if (info->is_tagpointer && (hmd_get_tagged_slot(info->addr) == HMD_TAG_NSString)) {
        return hmd_extractTaggedNSString(info->addr, dst, maxByteCount);
    }
    
    const struct HMDString string = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)info->addr, (void *)&string, sizeof(struct HMDString)) != HMD_ESUCCESS) {
        return 0;
    }
    
    int charCount = hmd_stringLength(&string);

    const char* src = hmd_stringStart(&string);
    if(HMDStrIsUnicode(&string)) {
        return hmd_copyAndConvertUTF16StringToUTF8(src, dst, charCount, maxByteCount);
    }

    return hmd_copy8BitString(src, dst, charCount, maxByteCount);
}

#pragma mark - private
int HMDAnalyzeStringContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    int result = hmd_copyStringContent(object , buffer, length);
    if (result > 0) {
        hmd_file_write_string_value(fd, buffer);
    }
    return result;
}

bool HMDReadStringContent(HMDCrashObjectInfo *object, char *buffer, int length) {
    return hmd_copyStringContent(object , buffer, length);
}
