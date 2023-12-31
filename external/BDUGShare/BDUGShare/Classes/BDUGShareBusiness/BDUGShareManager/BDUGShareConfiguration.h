//
//  BDUGShareConfiguration.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareConfiguration : NSObject

/// 本地模式，不请求数据接口
@property (nonatomic, assign, getter = isLocalMode) BOOL localMode;

/// 获取appid block
@property (nonatomic, copy, nullable) NSString *appID;

/// 获取did block
@property (nonatomic, copy, nullable) NSString *deviceID;

/// 可选参数，默认 https://i.snssdk.com
@property (nonatomic, copy) NSString *hostString;

+ (instancetype)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
