//
//  NSFileManager+IESEffectManager.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (IESEffectManager)

/**
 * This method calculates the accumulated size of a directory on the volume in bytes.
 */
+ (BOOL)ieseffect_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error;

+ (BOOL)ieseffect_getFileSize:(unsigned long long *)size filePath:(NSString *)filePath error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
