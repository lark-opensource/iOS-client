//
//  HeimdallrUtilities.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/10.
//

#import <Foundation/Foundation.h>

static inline void hmd_dispatch_main_async_safe(dispatch_block_t _Nullable block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void hmd_dispatch_main_sync_safe(dispatch_block_t _Nullable block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

extern char hmd_executable_path[FILENAME_MAX];
extern char hmd_main_bundle_path[FILENAME_MAX];
extern char hmd_home_path[FILENAME_MAX];

static inline bool hmd_is_in_app_bundle(const char * _Nullable path) {
    if (path == NULL) {
        return false;
    }
    if (strlen(hmd_main_bundle_path) == 0) {
        return false;
    }
    return strstr(path, hmd_main_bundle_path) != NULL;
}

@interface HeimdallrUtilities : NSObject

+ (NSString *_Nullable)dateStringFromDate:(NSDate *_Nullable)date
                          isUTC:(BOOL)isUTC
                  isMilloFormat:(BOOL)isMilloFormat;

+ (BOOL)isClassFromApp:(Class _Nullable )clazz;

+ (nullable id)payloadWithDecryptData:(nullable NSData *)data withKey:(nullable NSString *)key iv:(nullable NSString *)iv;

+ (NSString *_Nullable)libraryPath;

+ (NSString *_Nullable)heimdallrRootPath;

+ (NSString *_Nullable)systemVersion; //thread safe, same as UIDevice.systemVersion

+ (NSString *_Nullable)systemName; //thread safe, same as UIDevice.systemVersion

+ (BOOL)isiOSAppOnMac;

+ (NSString *_Nullable)modelIdentifier;

+ (BOOL)canFindDebuggerAttached;

@end
