//
// Created by 张海阳 on 2020/2/20.
//

#import "CJPayBaseRequest.h"
#import "CJPayCashDeskSendSMSResponse.h"


@interface CJPayCashDeskSendSMSRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params
             bizContent:(NSDictionary *)bizContent
               callback:(void (^)(NSError *error, CJPayCashDeskSendSMSResponse *))callback;

@end
