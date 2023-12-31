//
//  CJPayVerifyIDVCProtocol.h
//  CJPay
//
//  Created by 王新华 on 4/21/20.
//

#ifndef CJPayVerifyIDVCProtocol_h
#define CJPayVerifyIDVCProtocol_h

#import "CJPayBDCreateOrderResponse.h"
#import "CJPayTrackerProtocol.h"

@protocol CJPayVerifyIDVCProtocol <NSObject>

@property (nonatomic, copy) void(^completion) (NSString *);

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate; // 埋点上报代理

- (void)clearInput;

- (void)updateTips:(NSString *)text;

- (void)updateErrorText:(NSString *)text;

@end


#endif /* CJPayVerifyIDVCProtocol_h */
