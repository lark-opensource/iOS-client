//
//  CJPayServerEventCenter.m
//  Pods
//
//  Created by 王新华 on 2021/8/9.
//

#import "CJPayServerEventCenter.h"

#import "CJPayServerEventPostRequest.h"
#import "CJPaySDKMacro.h"

@implementation CJPayServerEventCenter

+ (instancetype)defaultCenter {
    static CJPayServerEventCenter *center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [CJPayServerEventCenter new];
    });
    return center;
}

- (void)postEvent:(NSString *)eventName
intergratedMerchantId:(NSString *)intergratedMerchantId
            extra:(NSDictionary *)extra
       completion:(nullable void (^)(void))completion {
    CJPayServerEvent *serverEvent = [CJPayServerEvent new];
    serverEvent.eventName = eventName;
    serverEvent.intergratedMerchantId = intergratedMerchantId;
    serverEvent.extra = extra;
    
    [CJPayServerEventPostRequest postEvents:@[serverEvent] completion:^(NSError * _Nonnull error, CJPayBaseResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completion);
    }];
}

@end
