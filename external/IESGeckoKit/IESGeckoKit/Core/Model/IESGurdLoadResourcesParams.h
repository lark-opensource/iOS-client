//
//  IESGurdLoadResourcesParams.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/19.
//

#import <Foundation/Foundation.h>

#import "IESGurdFetchResourcesParams.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, IESGurdLoadResourceOption) {
    IESGurdLoadResourceOptionNone = 0,
    IESGurdLoadResourceOptionAlwaysFetch = 1 << 1, // 每次都发起请求拉取最新资源
    IESGurdLoadResourceOptionForceRequest = 1 << 2, // 当 Gecko 开关关闭时，强制请求
    IESGurdLoadResourceOptionDisableThrottle = 1 << 3 // 关闭请求频控
};

@interface IESGurdLoadResourcesParams : NSObject

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy) NSString *resourcePath;

@property (nonatomic, copy) NSString *SDKVersion;

@property (nonatomic, copy) NSDictionary *customParams;

@property (nonatomic, assign) IESGurdDownloadPriority downloadPriority;

@property (nonatomic, assign) IESGurdLoadResourceOption options;

- (IESGurdFetchResourcesParams *)toFetchParams;

@end

NS_ASSUME_NONNULL_END
