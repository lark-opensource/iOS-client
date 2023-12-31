//
//  IESGurdSettingsRequestMeta.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsRequestParamsInfo : NSObject

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSArray<NSString *> *groupNamesArray;

@property (nonatomic, copy) NSArray<NSString *> *channelsArray;

@end

@interface IESGurdSettingsRequestInfo : NSObject

@property (nonatomic, assign) NSInteger delay;

@property (nonatomic, copy) NSArray<IESGurdSettingsRequestParamsInfo *> *paramsInfosArray;

@end

@interface IESGurdSettingsPollingInfo : NSObject

@property (nonatomic, assign) NSInteger interval;

@property (nonatomic, copy) NSArray<NSString *> *paramsInfosArray;

@end

@interface IESGurdSettingsLazyResourceInfo : NSObject

@property (nonatomic, copy) NSArray<NSString *> *channels;

@end

@interface IESGurdSettingsRequestMeta : NSObject

@property (nonatomic, assign, getter=isRequestEnabled) BOOL requestEnabled;

@property (nonatomic, assign, getter=isPollingEnabled) BOOL pollingEnabled;

@property (nonatomic, assign, getter=isFrequenceControlEnable) BOOL frequenceControlEnable;

@property (nonatomic, copy) NSArray<NSString *> *accessKeysArray;

@property (nonatomic, copy) NSArray<IESGurdSettingsRequestInfo *> *requestInfosArray;

@property (nonatomic, copy) NSDictionary<NSString *, IESGurdSettingsPollingInfo *> *pollingInfosDictionary;

@property (nonatomic, copy) NSDictionary<NSString *, IESGurdSettingsLazyResourceInfo *> *lazyResourceInfosDictionary;

+ (instancetype)metaWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
