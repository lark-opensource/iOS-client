//
//  IESGurdSettingsResourceBaseConfig.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsResourceConfigCDNFallBack : NSObject

@property (nonatomic, copy) NSArray<NSString *> *domainsArray;

@property (nonatomic, assign) NSInteger maxAttempts;

@property (nonatomic, assign) BOOL shuffle;

@end

@interface IESGurdSettingsResourceConfigCDNMultiVersion : NSObject
/// domians that support CDN multi version
@property (nonatomic, copy) NSArray<NSString *> *domainsArray;

@end

@interface IESGurdSettingsResourceConfigPipelineItem : NSObject

@property (nonatomic, assign) IESGurdSettingsPipelineType type;

@property (nonatomic, assign) IESGurdSettingsPipelineUpdatePolicy updatePolicy;

@property (nonatomic, assign) BOOL disableCache;

@end

@interface IESGurdSettingsResourceBaseConfig : NSObject

@property (nonatomic, strong) IESGurdSettingsResourceConfigCDNFallBack *CDNFallBack;

@property (nonatomic, copy) NSArray<IESGurdSettingsResourceConfigPipelineItem *> *pipelineItemsArray;

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *prefixToAccessKeyDictionary;

@property (nonatomic, strong) IESGurdSettingsResourceConfigCDNMultiVersion *CDNMultiVersion;

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
