//
//  HMDCrashContentAnalyzeBase.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashContentAnalyzeBase.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashURLAnalyze.h"
#include "HMDCrashArrayAnalyze.h"
#include "HMDCrashStringAnalyze.h"
#include "HMDCrashDictionaryAnalyze.h"

#include "HMDObjcRuntime.h"

#pragma mark - static variable

//__NSFrozenDictionaryM 依然是不可变数组
static HMDClassData hmd_analyzeClass[] = {
    {"__NSCFString", HMDObjCClassTypeString, HMDClassSubtypeNone, HMDAnalyzeStringContent},
    {"NSCFString", HMDObjCClassTypeString, HMDClassSubtypeNone, HMDAnalyzeStringContent},
    {"__NSCFConstantString", HMDObjCClassTypeString, HMDClassSubtypeNone, HMDAnalyzeStringContent},
    {"NSCFConstantString", HMDObjCClassTypeString, HMDClassSubtypeNone, HMDAnalyzeStringContent},
    {"__NSSingleObjectArrayI", HMDObjCClassTypeArray, HMDClassSubtypeNSArraySingle, HMDAnalyzeNSArrayContent},
    {"__NSArrayI", HMDObjCClassTypeArray, HMDClassSubtypeNSArrayImmutable, HMDAnalyzeNSArrayContent},
    {"__NSArrayM", HMDObjCClassTypeArray, HMDClassSubtypeNSArrayMutable, HMDAnalyzeNSArrayContent},
    {"__NSSingleEntryDictionaryI", HMDObjCClassTypeDictionary, HMDClassSubtypeNSDictionaySingle, HMDAnalyzeNSDictionaryContent},
    {"__NSDictionaryI", HMDObjCClassTypeDictionary, HMDClassSubtypeNSDictionayImmutable, HMDAnalyzeNSDictionaryContent},
    {"__NSFrozenDictionaryM", HMDObjCClassTypeDictionary, HMDClassSubtypeNSDictionayFrozen, HMDAnalyzeNSDictionaryContent},
    {"__NSDictionaryM", HMDObjCClassTypeDictionary, HMDClassSubtypeNSDictionayMutable, HMDAnalyzeNSDictionaryContent},
    {"__NSCFNumber", HMDObjCClassTypeNumber, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"NSNumber", HMDObjCClassTypeNumber, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"NSURL", HMDObjCClassTypeNumber, HMDClassSubtypeNone, HMDAnalyzeNSURLContent},
    {NULL, HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
};

static HMDClassData hmd_tagPointerClass[] = {
    {"TAG_NSAtom", HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"TAG_1", HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"TAG_NSString", HMDObjCClassTypeString, HMDClassSubtypeNone, HMDAnalyzeStringContent},
    {"TAG_NSNumber", HMDObjCClassTypeNumber, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"TAG_NSIndexPath", HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"TAG_NSManagedObjectID", HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {"TAG_NSDate", HMDObjCClassTypeDate, HMDClassSubtypeNone, HMDWriteObjectDescription},
    {NULL, HMDObjCClassTypeUnknown, HMDClassSubtypeNone, HMDWriteObjectDescription},
};

static int g_taggedClassDataCount = sizeof(hmd_tagPointerClass) / sizeof(*hmd_tagPointerClass);
static int g_analyzeClassDataCount = sizeof(hmd_analyzeClass) / sizeof(*hmd_analyzeClass);

#pragma mark - Public methods
int HMDWriteObjectDescription(int fd, HMDCrashObjectInfo *objectInfo, char *buffer, int length){ // 会以<Class: Address>的格式记录
    if (objectInfo) {
        const char* name = objectInfo->class_name;
        if (objectInfo->is_tagpointer) {
            HMDClassData data = hmd_tagPointerClass[hmd_get_tagged_slot(objectInfo->addr)];
            name = data.name;
        }
        
        if (!name || !strlen(name)) {
            name = HMDUnknownClassName();
        }
        uintptr_t objPointer = (uintptr_t)objectInfo->addr;
        hmd_file_write_string(fd, "\"<");
        hmd_file_write_string(fd, name);
        hmd_file_write_string(fd, ": 0x");
        hmd_file_write_uint64_hex(fd, objPointer);
        hmd_file_write_string(fd, ">\"");
        return true;
    }
    return 0;
}

const char *HMDUnknownClassName(void) {
    return "UnknownClassName";
}

bool HMDWritePlaceholder(int fd, uintptr_t ptr) {
    hmd_file_write_string(fd, "\"");
    hmd_file_write_string(fd, "placeholder_");
    hmd_file_write_string(fd, ": 0x");
    hmd_file_write_uint64_hex(fd, ptr);
    hmd_file_write_string(fd, "\"");
    return true;
}

HMDClassData *HMDFetchObjectClassData(HMDCrashObjectInfo *objectInfo) {
    if (objectInfo->is_tagpointer) {
        int slot = hmd_get_tagged_slot(objectInfo->addr);
        if (slot > g_taggedClassDataCount - 1) {
            return &hmd_tagPointerClass[g_taggedClassDataCount - 1];
        }
        return &hmd_tagPointerClass[slot];
    }
    
    // 类对象不做解析
    if (objectInfo->is_class) {
        return &hmd_analyzeClass[g_analyzeClassDataCount - 1];
    }
    
    const char* className = objectInfo->class_name;
    for (int i = 0; i < g_analyzeClassDataCount; i++) {
        HMDClassData *data = &hmd_analyzeClass[i];
        unlikely_if(data->name == NULL) {
            return data;
        }
        unlikely_if(strcmp(className, data->name) == 0) {
            return data;
        }
    }
    return &hmd_analyzeClass[g_analyzeClassDataCount - 1];
}

HMDObjCClassType HMDFetchObjectClassType(HMDCrashObjectInfo *objectInfo) {
    return HMDFetchObjectClassData(objectInfo)->type;
}

HMDClassSubtype HMDFetchObjectClassSubType(HMDCrashObjectInfo *objectInfo) {
    return HMDFetchObjectClassData(objectInfo)->subType;
}

