//
//  CJPaySuperPayCallBackModel.h
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2023/2/7.
//

#import <JSONModel/JSONModel.h>
@class CJPaySuperPayQueryResponse;
@class CJPayPaymentInfoModel;
typedef NS_ENUM(NSUInteger, CJPayResultType);
typedef NS_ENUM(NSUInteger, CJPayChannelType);
NS_ASSUME_NONNULL_BEGIN

@interface CJPaySuperPayCallBackModel : JSONModel

@property (nonatomic, assign) CJPayChannelType channelType;
@property (nonatomic, assign) CJPayResultType resultType;
@property (nonatomic, copy) NSString *errorCode;
@property (nonatomic, copy) NSDictionary *paymentInfo;// 透传paymentInfo字段

- (instancetype)initWithChannelType:(CJPayChannelType)type resultType:(CJPayResultType)resultType response:(CJPaySuperPayQueryResponse *)response;

@end

NS_ASSUME_NONNULL_END
