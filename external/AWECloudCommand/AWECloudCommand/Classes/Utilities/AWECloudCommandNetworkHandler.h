//
//  AWECloudCommandNetworkHandler.h
//  Aspects
//
//  Created by Stan Shan on 2018/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECloudCommandNetworkDelegate <NSObject>
@required
/// 请求方法
- (void)requestWithUrl:(NSString * _Nonnull)urlString
                method:(NSString * _Nonnull)method
                params:(NSDictionary * _Nullable)params
        requestHeaders:(NSDictionary *)requestHeaders
            completion:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completion;

/// 上传方法
- (void)uploadWithUrl:(NSString * _Nonnull)urlString
                 data:(NSData *)data
       requestHeaders:(NSDictionary *)requestHeaders
           completion:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completion;

@end


@interface AWECloudCommandNetworkHandler : NSObject <AWECloudCommandNetworkDelegate>

@property (atomic, strong) id<AWECloudCommandNetworkDelegate> networkDelegate;

/// 得到网络请求代理
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
