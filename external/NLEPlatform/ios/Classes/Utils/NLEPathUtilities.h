//
//  NLEPathUtilities.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEPathUtilities : NSObject

/// Get real resource file path from given nle resource node
/// @param file nle resource node that record absolute file path
+ (NSString * _Nullable)resourcePathForFilePath:(NSString *)file;

/// Get real resource file path from given nle resource node
/// @param file nle resource node that record relative file path
/// @param folder  folder & file forms a abspath
+ (NSString * _Nullable)resourcePathForFilePath:(NSString *)file folder:(NSString *_Nullable)folder;

@end

NS_ASSUME_NONNULL_END
