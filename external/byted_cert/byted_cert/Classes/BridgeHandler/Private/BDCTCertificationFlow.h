//
//  BDCTCertificationFlow.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/22.
//

#import "BDCTFlow.h"
@class BDCTCertificationFlow;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTCertificationFlow : BDCTFlow

@property (nonatomic, copy, nullable) void (^completionBlock)(NSError *_Nullable error, NSDictionary *_Nullable result);

- (void)begin;
- (void)finishFlowWithParams:(NSDictionary *)params progressType:(NSUInteger)progressType;
@end

NS_ASSUME_NONNULL_END
