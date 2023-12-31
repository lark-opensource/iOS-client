//
//  IESGurdSettingsConfig.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsConfig : NSObject

@property (nonatomic, copy) NSArray<NSString *> *hostAppIdsArray;

@property (nonatomic, assign) NSInteger pollingInterval;

@property (nonatomic, assign, getter=isPollingEnabled) BOOL pollingEnabled;

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
