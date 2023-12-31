//
//  OPMonitorCode.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPMonitorCode : NSObject <OPMonitorCodeProtocol>

/// 业务域，参与ID计算
@property (nonatomic, strong, nonnull, readonly) NSString *domain;

/// 业务域内唯一编码 code，参与ID计算
@property (nonatomic, assign, readonly) NSInteger code;

/// 唯一识别ID，格式为：{version}-{domain}-{code}
@property (nonatomic, strong, nonnull, readonly) NSString *ID;
/// 建议级别（不代表最终级别），不参与ID计算
@property (nonatomic, assign, readonly) OPMonitorLevel level;

/// 相关信息，不参与ID计算
@property (nonatomic, strong, nonnull, readonly) NSString *message;

/**
 * @param domain 业务域，参与ID计算
 * @param code 业务域内唯一编码 code，参与ID计算
 * @param level 建议级别（不代表最终级别），不参与ID计算
 * @param message 相关信息，不参与ID计算
 */
- (instancetype _Nonnull)initWithDomain:(NSString * _Nonnull)domain
                                   code:(NSInteger)code
                                  level:(OPMonitorLevel)level
                                message:(NSString * _Nonnull)message;

- (instancetype _Nonnull)initWithCode:(id<OPMonitorCodeProtocol> _Nonnull)code;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
