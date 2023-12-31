//
//  CJPayTransferInfoModel.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceVerifyInfo;
@interface CJPayTransferInfoModel : JSONModel

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *outTradeNo;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *needFace;
@property (nonatomic, copy) NSString *lynxUrl;
@property (nonatomic, copy) NSString *processId;
@property (nonatomic, strong) CJPayFaceVerifyInfo *faceVerifyInfo;
@property (nonatomic, copy) NSString *needBindCard;
@property (nonatomic, copy) NSString *zgAppId;
@property (nonatomic, copy) NSString *zgMerchantId;
@property (nonatomic, copy) NSString *needQueryFaceData;
@property (nonatomic, copy) NSString *needOpenAccount;
@property (nonatomic, copy) NSString *openAccountUrl;

@property (nonatomic, copy) NSDictionary *trackInfoDic;

@end

NS_ASSUME_NONNULL_END
