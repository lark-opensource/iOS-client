#ifndef UMSG_EXT_H
#define UMSG_EXT_H
#if !UCONFIG_NO_FORMATTING

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/// readonly UTF16 String
typedef struct {
    const uint16_t* buffer;
    int32_t len; ///< uint16_t count(not byte size), -1 means null termiated C String
} U16_String;

enum UValueType {
  UValue_Date = 0,
  UValue_Double,
  UValue_Long,
  UValue_String,
  // UValue_Array,
  UValue_Int64,
  // UValue_Object,
};
typedef struct {
    enum UValueType ftype;
    union {
        // UObject*        fObject;
        U16_String fString;
        double     fDouble;
        int32_t    fLong;
        int64_t    fInt64;
        double     fDate; ///< timestamp milliseconds from 1970
    } fvalue;
} UValue;

typedef struct {
    U16_String key;
    UValue value;
} UFormatPair;

static inline UValue uvalue_from_string(U16_String value) {
    return (UValue){ .ftype = UValue_String, .fvalue.fString = value };
}
static inline UValue uvalue_from_double(double value) {
    return (UValue){ .ftype = UValue_Double, .fvalue.fDouble = value };
}
static inline UValue uvalue_from_date(double value) {
    return (UValue){ .ftype = UValue_Date, .fvalue.fDate = value };
}
static inline UValue uvalue_from_long(int32_t value) {
    return (UValue){ .ftype = UValue_Long, .fvalue.fLong = value };
}
static inline UValue uvalue_from_int64(int64_t value) {
    return (UValue){ .ftype = UValue_Int64, .fvalue.fInt64 = value };
}

/**
 * format message by key-value args
 *
 * @param locale The locale for which the message will be formatted. null terminated UTF8 C String
 * @param pattern The pattern specifying the message's format
 * @param args A array pointer to UFormatPair, if no args, can pass NULL and 0 length.
 * @param argsLength The count of arg.
 * @param result A pointer to a buffer to receive the formatted message.
 * @param resultLength The maximum count of result can be filled.
 * @param status A pointer to an UErrorCode to receive any errors. see UErrorCode.
 *      >0 means has error. you must check the result before use the return U16_String.
 *      NOTE: **should init to zero or will return error directly**
 * @return the formatedMessage U16_String.
 *      if greater than result length, return a malloc buffer(pointer not equal to result)
 *          and you should call **free** to release it.
 *      if has error, may return null buffer
 *
 *
 * @example

#include <stdio.h>
// 各平台应该自己使用对应的字符串和utf8<->utf16转换的能力
#include <CoreFoundation/CoreFoundation.h>
#include "unicode/umsg_ext.h"

void testIcuInC(void) {
    int32_t status = 0;
    const int32_t resultLength = (1<<12);
    uint16_t result[resultLength] = {0};

    uint16_t* pattern = u"{norm} {argument, plural, one{C''est # fichier {norm}} other {Ce sont # fichiers}} dans la liste. "
        "\n{noun, select, varsh {{count, selectordinal, one{#lā} two{#rā} few{#thā} many{#Thā} other {#vān} } vrh}"
        "                 other {{count, selectordinal, one{#lī} two{#rī} few{#thī} many{#Thī} other {#vīn} } {noun}} }"
        "\nMy OKR progress is {count, number, percent} complete"
        "\nToday is {nowTime, date, full}, time is {nowTime, time, full}"
        "\n{noun, select, varsh {He} other {She} } likes programming";
    UFormatPair args[5] = {
        (UFormatPair){
            .key = {u"argument", -1},
            .value = uvalue_from_int64(10000)
        }
        ,(UFormatPair){
            .key = {u"norm", -1},
            .value = uvalue_from_string((U16_String){u"你好", -1})
        }
        ,(UFormatPair){
            .key = {u"noun", -1},
            .value = uvalue_from_string((U16_String){u"varsh", -1})
        }
        ,(UFormatPair){
            .key = {u"count", -1},
            .value = uvalue_from_long(22)
        }
        ,(UFormatPair){
            .key = {u"nowTime", -1},
            .value = uvalue_from_date(3600 * 24 * 9 * 1000)
        }
    };

    // call format key-value
    U16_String output = u_formatMessage_kv("en_CN", (U16_String){ pattern, -1 }, args, 5, result, resultLength, &status);
    if ( status > 0 || output.buffer == NULL) { // NOTE: >0 means has error
        printf("error format with code %d", status);
        goto free_output;
    }
    // convert output.buffer and output.len to platform string
    // testcode simple print it..
    CFStringRef cf_output = CFStringCreateWithCharactersNoCopy(NULL, output.buffer, output.len, kCFAllocatorNull);
    char u8buffer[1<<12];
    CFStringGetCString(cf_output, u8buffer, 1<<12, kCFStringEncodingUTF8);
    char* expect = "你好 Ce sont 10,000 fichiers dans la liste. "
        "\n22rā vrh"
        "\nMy OKR progress is 2,200% complete"
        "\nToday is Saturday, January 10, 1970, time is 8:00:00 AM "
        "\nHe likes programming";
    if ( strncmp(u8buffer, expect, strlen(expect)) != 0 ) {
        printf("output not equal to expect");
    }
    printf("output is %s", u8buffer);
    CFRelease(cf_output);

    // if no args, can pass NULL args, and argLength is 0;
    U16_String output2 = u_formatMessage_kv("zh_CN", (U16_String){u"hello", -1}, NULL, 0, result, resultLength, &status);
    if (memcmp(output2.buffer, u"hello", 10) != 0) {
        printf("no args output not equal to expect");
    }
    // ouptut2 not need to free, since it's output must small than resultLength

free_output:
    if ( output.buffer != result ) {
        free((void*)output.buffer); // NOTE: must free allocate buffer when provide buffer not enough.
    }
}
 */
extern U16_String
u_formatMessage_kv(
    const char       *locale,

    const U16_String pattern,
    const UFormatPair* args,
    int32_t argsLength,

    uint16_t *result,
    int32_t  resultLength,
    int32_t  *status
);

#ifdef __cplusplus
}
#endif

#endif // !UCONFIG_NO_FORMATTING
#endif /* ifndef UMSG_EXT_H */
