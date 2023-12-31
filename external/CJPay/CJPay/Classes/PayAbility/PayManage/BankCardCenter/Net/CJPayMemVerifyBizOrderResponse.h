//
//  CJPayMemVerifyBizOrderResponse.h
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayBaseResponse.h"

#import "CJPayErrorButtonInfo.h"
#import "CJPayMemberFaceVerifyInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemVerifyBizOrderResponse : CJPayBaseResponse

@property (nonatomic, assign) BOOL needSignCard;
@property (nonatomic, copy) NSString *signOrderNo;

@property (nonatomic, copy) NSString *additionalVerifyType;
@property (nonatomic, strong) CJPayMemberFaceVerifyInfoModel *faceVerifyInfoModel;

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
