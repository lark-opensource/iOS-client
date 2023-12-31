//
//  NSString+CameraClientResource.h
//  CameraClient
//
//  Created by Liu Deping on 2019/11/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *ACCResourceFile(NSString *name);

@interface NSString (CameraClientResource)

+ (NSString *)acc_strValueWithName:(NSString *)name;

+ (NSString *)acc_filePathWithName:(NSString *)fileName;

+ (NSString *)acc_filePathWithName:(NSString *)fileName inDirectory:(NSString *)directory;

+ (NSString *)acc_configInfoWithName:(NSString *)name;

+ (NSString *)acc_bundlePathWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
