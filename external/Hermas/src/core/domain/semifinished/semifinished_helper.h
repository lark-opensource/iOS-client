//
//  semifinished_helper.h
//  Hermas
//
//  Created by liuhan on 2022/4/8.
//

#ifndef semifinished_helper_h
#define semifinished_helper_h

#define STRUCT_FILE_BLOCK_LENGTH (78 + sizeof(int32_t) * 2 + 1)
#define STRUCT_FILE_BLOCK_STR_LENGTH 78

#define SEMIRECORDHEADERLEN (SEMIISUSELEN + SEMIBLOCKLENLEN + SEMITRACEIDLEN)
#define SEMIISUSELEN 1
#define SEMIBLOCKLENLEN sizeof(int32_t)
#define SEMITRACEIDLEN 32
#define SEMISPANIDLEN 16
#define SEMIBLOCKNOTUSE "0"
#define SEMIBLOCKISUSE "1"

#include "string_util.h"

namespace hermas {

enum SemiRecordType {
    IsTraceRecord = 0,
    IsSpanRecord,
    IsInValidRecord,
};

}


#endif /* semifinished_helper_h */
