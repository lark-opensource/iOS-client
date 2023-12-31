//
//  IESGurdPackagesExtraManager.h
//  IESGeckoKit
//
//  Created by xinwen tan on 2022/2/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPackagesExtraManager : NSObject

+ (instancetype)sharedManager;

- (nullable NSDictionary *)getExtra:(NSString *)accsskey channel:(NSString *)channel;

- (void)updateExtra:(NSString *)accsskey channel:(NSString *)channel data:(NSDictionary *)data;

- (void)cleanExtraIfNeeded:(NSString *)accsskey channel:(NSString *)channel;

- (void)saveToFile;

- (void)setup;

@end

NS_ASSUME_NONNULL_END
