//
//  NLEFileManager.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEFileManager : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)filePath;
+ (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)parentFilePath;

@end

NS_ASSUME_NONNULL_END
