//
//  BDAutoTrackDeviceHelper+CAID.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/24.
//

#import "BDAutoTrackDeviceHelper+CAID.h"
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <sys/xattr.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>
#include <objc/message.h>
#include <sys/stat.h>
#include <dirent.h>
#include <sys/dirent.h>
#include <uuid/uuid.h>

#pragma mark - caid补充字段 https://bytedance.feishu.cn/docs/doccnGziebKN3gMwgudiPPyrAce
/*!
 设备名称（小写MD5）
 */
NSString *bd_device_phone_name() {
    const char *original_str = [[UIDevice currentDevice].name UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}

/*!
 示例(真机): D20AP
 */
NSString *bd_device_hardware_model() {
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.model", answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

/*!
 示例(需要真机): zh-Hans-CN
 */
NSString *bd_device_locale_language() {
    if ([NSLocale preferredLanguages].count > 0) {
        return [NSLocale preferredLanguages].firstObject;
    }
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
}

/* ct_uuid */
//static __attribute__((__always_inline__)) uint32_t gnu_hash(const char *func_name, const uint32_t length) {
//    uint32_t h = 5381;
//    uint32_t index = 0;
//    while (index < length) {
//        h += (h << 5) + func_name[index++];
//    }
//
//    return h;
//}
//
//static __attribute__((__always_inline__)) uint32_t elf_hash(const char *name, const uint32_t length) {
//    uint32_t h = 0, g = 0;
//    uint32_t index = 0;
//    while (index < length) {
//        h = (h << 4) + name[index++];
//        g = h & 0xf0000000;
//        h ^= g;
//        h ^= g >> 24;
//    }
//
//    return h;
//}

/* 示例(需要真机): 5d4a885f-844a-885f-ff47-885f7efff53f  */
//NSString *bd_device_ct_uuid() {
//    NSArray<NSString *> *fileList = @[
//        @"L1N5c3RlbS9MaWJyYXJ5L0NvcmVTZXJ2aWNlcy9DaGVja3BvaW50LnhtbA==", // /System/Library/CoreServices/Checkpoint.xml
//        @"L3Vzci9zaGFyZS9taXNjL3RyYWNlLmNvZGVz",  // /usr/share/misc/trace.codes
//    ];
//    NSUInteger result = 0;
//    char szTargetPath[NAME_MAX];
//    struct stat sb;
//    uint32_t timestamp[4];
//    for (NSUInteger index = 0; index < fileList.count; index++) {
//        NSString *file = [fileList objectAtIndex:index];
//        memset(szTargetPath, 0, NAME_MAX);
//        NSData *data = [[NSData alloc] initWithBase64EncodedString:file
//                                                           options:NSDataBase64DecodingIgnoreUnknownCharacters];
//
//        [data getBytes:szTargetPath length:MIN(data.length, NAME_MAX)];
//        if (stat(szTargetPath, &sb) != 0) {
//            result = index + 5;
//            break;
//        }
//        timestamp[index] = (uint32_t)(sb.st_ctimespec.tv_sec);
//    }
//
//    if (result > 0) {
//        return nil;
//    }
//
//    memset(szTargetPath, 0, NAME_MAX);
//    *(uint64_t*)(szTargetPath + 0 * sizeof(uint64_t)) = 0x6168732f7273752f;
//    *(uint64_t*)(szTargetPath + 1 * sizeof(uint64_t)) = 0x776d7269662f6572;
//    *(uint64_t*)(szTargetPath + 2 * sizeof(uint64_t)) = 0x696669772f657261;
//
//    DIR* dir_w = opendir(szTargetPath);
//    if (dir_w == NULL) {
//        return nil;
//    }
//
//    char szTmp[NAME_MAX];
//    struct dirent *ptr;
//    result = 8;
//    while ((ptr = readdir(dir_w)) != NULL && result != 0) {
//        if (ptr->d_namlen < 2 || ptr->d_type != DT_DIR) {
//            continue;
//        }
//
//        memset(szTmp, 0, NAME_MAX);
//        snprintf(szTmp, NAME_MAX, "%s/%s", szTargetPath, ptr->d_name);
//        if(stat(szTmp, &sb) != 0) {
//            result = 5;
//            break;
//        }
//
//        DIR* dir_i = opendir(szTmp);
//        if (dir_i == NULL) {
//            continue;
//        }
//
//        while ((ptr = readdir(dir_i)) != NULL)  {
//            if(ptr->d_namlen < 3
//               || ptr->d_type == DT_DIR
//               || strstr(ptr->d_name, "-")) {
//                continue;
//            }
//            const char* d_name = ptr->d_name;
//            if (memcmp(d_name + ptr->d_namlen - 4, ".trx", 4) != 0) {
//                continue;
//            }
//
//            snprintf(szTmp, NAME_MAX, "%s/%s", szTmp, ptr->d_name);
//            if (stat(szTmp, &sb) == 0) {
//                timestamp[2] = (uint32_t)(sb.st_ctimespec.tv_sec);
//                uint32_t value = elf_hash(d_name, ptr->d_namlen) | gnu_hash(d_name, ptr->d_namlen);
//                timestamp[3] = value;
//                /// read once
//                result = 0;
//            }
//
//            break;
//        }
//        closedir(dir_i);
//    }
//    closedir(dir_w);
//
//    if (result > 0) {
//        return nil;
//    }
//
//    uuid_t uuid;
//    uuid_clear(uuid);
//    for (NSUInteger tIndex = 0; tIndex < 4; tIndex++) {
//        uint32_t t = timestamp[tIndex];
//        memcpy(uuid + tIndex * sizeof(uint32_t), &t, sizeof(uint32_t));
//    }
//    uuid_string_t unparsedUUID;
//    uuid_unparse_lower(uuid, unparsedUUID);
//    NSString *value = [[NSString alloc] initWithUTF8String:unparsedUUID];
//
//    return value;
//}
