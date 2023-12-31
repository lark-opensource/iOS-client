//
//  BDTuringVerifyViewDefine.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyView;

@protocol BDTuringVerifyViewDelegate <NSObject>

@optional

- (void)verifyViewDidShow:(BDTuringVerifyView *)verifyView;
- (void)verifyViewDidHide:(BDTuringVerifyView *)verifyView;

- (void)verifyWebViewLoadDidSuccess:(BDTuringVerifyView *)verifyView;
- (void)verifyWebViewLoadDidFail:(BDTuringVerifyView *)verifyView;

@end

FOUNDATION_EXTERN BDTuringVerifyType const BDTuringVerifyTypeSMS;       ///< sms
FOUNDATION_EXTERN BDTuringVerifyType const BDTuringVerifyTypePicture;   ///< pic
FOUNDATION_EXTERN BDTuringVerifyType const BDTuringVerifyTypeQA;        ///< qa
FOUNDATION_EXPORT BDTuringVerifyType const BDTuringVerifyTypeSmart;


NS_ASSUME_NONNULL_END
