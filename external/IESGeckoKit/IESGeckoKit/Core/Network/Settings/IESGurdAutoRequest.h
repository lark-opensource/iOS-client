//
//  IESGurdAutoRequest.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/23.
//

#import "IESGurdMultiAccessKeysRequest.h"

#import "IESGurdSettingsRequestMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdAutoRequest : IESGurdMultiAccessKeysRequest

- (void)updateConfigWithParamsInfosArray:(NSArray<IESGurdSettingsRequestParamsInfo *> *)paramsInfosArray;

@end

NS_ASSUME_NONNULL_END
