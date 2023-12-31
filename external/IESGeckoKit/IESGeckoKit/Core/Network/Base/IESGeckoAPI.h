//
//  IESGurdAPI.h
//  IESGurdKit
//
//  Created by willorfang on 2018/5/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *IESGurdSettingsAPIVersion;

@interface IESGurdAPI : NSObject

+ (NSString *)packagesInfo;

+ (NSString *)polling;

+ (NSString *)settings;

@end

NS_ASSUME_NONNULL_END
