//
//  CJPayGetTicketResponse.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/20.
//

#import <JSONModel/JSONModel.h>
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayGetTicketResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *ticket;
@property (nonatomic, assign) BOOL isSigned;
@property (nonatomic, copy) NSString *agreementUrl;
@property (nonatomic, copy) NSString *agreementDesc;
@property (nonatomic, copy) NSString *nameMask;
@property (nonatomic, copy) NSString *scene;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, copy) NSString *liveRoute;
@property (nonatomic, copy) NSString *protocolCheckBox;
@property (nonatomic, copy) NSString *faceScene; //活体动作场景

- (NSUInteger)getEnterFromValue;
- (NSString *)getLiveRouteTrackStr;

@end

NS_ASSUME_NONNULL_END
