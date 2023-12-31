//
//  OKSandbox.h
//  OneKit
//
//  Created by bob on 2020/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKSandbox : NSObject

+ (NSString *)appName;/// CFBundleName
+ (NSString *)appDisplayName; /// CFBundleDisplayName
+ (NSString *)appVersion; /// CFBundleShortVersionString
+ (NSString *)appBuildVersion; /// CFBundleVersion
+ (NSString *)bundleID; /// CFBundleIdentifier

@end

NS_ASSUME_NONNULL_END
