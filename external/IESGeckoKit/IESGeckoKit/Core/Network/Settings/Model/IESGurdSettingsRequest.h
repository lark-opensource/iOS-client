//
//  IESGurdSettingsRequest.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import <Foundation/Foundation.h>
#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsRequest : NSObject

@property (nonatomic, assign) NSInteger version;

@property (nonatomic, assign) IESGurdEnvType env;

@property (nonatomic, assign) IESGurdSettingsRequestType requestType;

+ (instancetype)request;

- (NSDictionary *)paramsForRequest;

- (NSDictionary *)logInfo;

@end

NS_ASSUME_NONNULL_END
