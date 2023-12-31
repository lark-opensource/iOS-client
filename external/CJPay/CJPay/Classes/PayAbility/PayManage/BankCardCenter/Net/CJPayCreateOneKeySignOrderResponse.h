//
//  CJPayCreateOneKeySignOrderResponse.h
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayErrorButtonInfo;
@class CJPayMemberFaceVerifyInfoModel;
@interface CJPayCreateOneKeySignOrderResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *bankUrl;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, copy) NSString *postData;
@property (nonatomic, copy) NSString *signOrder;

@property (nonatomic, copy) NSString *additionalVerifyType;
@property (nonatomic, copy) CJPayMemberFaceVerifyInfoModel *faceVerifyInfoModel;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, assign) BOOL isMiniApp;

- (BOOL)needVerifyPassWord;
- (BOOL)needLiveDetection;

@end

NS_ASSUME_NONNULL_END
