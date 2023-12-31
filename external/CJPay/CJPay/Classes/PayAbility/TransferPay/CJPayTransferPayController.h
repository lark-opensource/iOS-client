//
//  CJPayTransferPayController.h
//  CJPay-5b542da5
//
//  Created by 尚怀军 on 2022/10/28.
//

#import <Foundation/Foundation.h>
#import "CJPayManagerDelegate.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN
@interface CJPayTransferPayController : NSObject<CJPayBaseLoadingProtocol>

- (void)startPaymentWithParams:(NSDictionary *)params
                    completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion;

@end

NS_ASSUME_NONNULL_END
