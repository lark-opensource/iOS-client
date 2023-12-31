//
//  DVEFileUtils.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEFileUtils : NSObject

+ (void)copyFileFromPath:(NSString *)sourcePath toPath:(NSString *)toPath;

+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)err;

+ (NSTimeInterval)durationWithPath:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
