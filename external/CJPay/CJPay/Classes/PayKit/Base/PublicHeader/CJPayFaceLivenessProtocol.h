//
//  CJPayFaceLivenessProtocol.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/18.
//

#ifndef CJPayFaceLivenessProtocol_h
#define CJPayFaceLivenessProtocol_h

NS_ASSUME_NONNULL_BEGIN

typedef  void(^CJPayFaceLivenessCallBack)(NSDictionary * _Nullable data, NSError * _Nullable error);

@protocol CJPayFaceLivenessProtocol <NSObject>

// 活体识别，采集人脸照片
- (void)doFaceLivenessWith:(NSDictionary *)params
               extraParams:(NSDictionary *)extraParams
                  callback:(CJPayFaceLivenessCallBack)callback;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayFaceLivenessProtocol_h */
