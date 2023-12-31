//
//  DYOpenSettingsInternalBridge.h
//  DouyinOpenPlatformSDK-6252ab7f
//
//  Created by ByteDance on 2023/5/23.
//

#import <Foundation/Foundation.h>

@protocol DYOpenSettingsInternalBridge <NSObject>

@optional

- (void)s_requestSettings;

/**
 @brief 获取整型值配置，取不到返回默认值
 @param key key
 */
- (NSInteger)s_integerValueForKey:(NSString *_Nonnull)key defaultInteger:(NSInteger)defaultInteger;


@end
