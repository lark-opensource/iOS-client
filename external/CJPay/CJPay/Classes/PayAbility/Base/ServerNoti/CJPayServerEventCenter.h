//
//  CJPayServerEventCenter.h
//  Pods
//
//  Created by 王新华 on 2021/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayServerEventCenter : NSObject

+ (instancetype)defaultCenter;

/// 发送服务端事件通知
/// @param eventName 事件名称
/// @param intergratedMerchantId 聚合侧的商户号
/// @param extra 事件具体内容，可以以字典形式传入
/// @param completion 回调
- (void)postEvent:(NSString *)eventName
intergratedMerchantId:(NSString *)intergratedMerchantId
            extra:(NSDictionary *)extra
       completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
