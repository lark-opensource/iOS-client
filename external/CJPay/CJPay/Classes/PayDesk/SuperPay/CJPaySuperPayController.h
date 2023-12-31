//
//  CJPaySuperPayController.h
//  
//
//  Created by 易培淮 on 2022/5/30.
//

#import "CJPayLoadingManager.h"


NS_ASSUME_NONNULL_BEGIN
@class CJPaySuperPayQueryResponse;
@class CJPayNavigationController;
@class CJPaySuperPayQueryResponse;
typedef NS_ENUM(NSUInteger, CJPayOrderStatus);
typedef NS_ENUM(NSUInteger, CJPayResultType);
@interface CJPaySuperPayController : NSObject<CJPayBaseLoadingProtocol>

@property (nonatomic, copy) void(^completion)(CJPayResultType resultType, CJPaySuperPayQueryResponse * __nullable response);
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, strong, readonly) CJPayNavigationController *navigationController;

- (BOOL)isNewVCBackWillExistPayProcess;
- (void)startQueryResultWithParams:(NSDictionary *)dict;
- (void)startVerifyWithChannelData:(NSString *)channelData
                        completion:(void (^)(CJPayOrderStatus orderStatus, NSString *msg))completion;

@end

NS_ASSUME_NONNULL_END
