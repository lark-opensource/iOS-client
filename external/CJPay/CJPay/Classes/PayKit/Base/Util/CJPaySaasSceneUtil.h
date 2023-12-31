//
//  CJPaySaasSceneUtil.h
//  CJPay
//
//  Created by 利国卿 on 2023/7/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString * const CJPaySaasKey;

@interface CJPaySaasRecordModel : NSObject

- (instancetype)initWithKey:(nonnull NSString *)key saasScene:(NSString *)saasScene;
@end

@interface CJPaySaasSceneUtil : NSObject
// 添加SaaS标识（入栈）
+ (void)addSaasKey:(nonnull NSString *)recordKey saasSceneValue:(NSString *)saasScene;
// 获取当前支付流程的SaaS标识（栈顶）
+ (nullable NSString *)getCurrentSaasSceneValue;
// 移除当前SaaS标识（出栈）
+ (void)removeSaasSceneByKey:(NSString *)saasRecordKey;
@end

NS_ASSUME_NONNULL_END
