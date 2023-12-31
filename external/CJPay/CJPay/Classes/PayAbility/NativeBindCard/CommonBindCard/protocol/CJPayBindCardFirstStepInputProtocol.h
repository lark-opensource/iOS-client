//
//  CJPayBindCardFirstStepInputProtocol.h
//  Pods
//
//  Created by renqiang on 2021/9/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemBankInfoModel;
@class CJPayMemCardBinResponse;
@protocol CJPayBindCardFirstStepInputProtocol <NSObject>

@required
- (void)updateCardNumContainerPlaceHolderTextWithName:(NSString *)name;
- (void)updateCardTipsMemBankInfoModel:(CJPayMemBankInfoModel *)model;
- (void)updateCardTipsWithWarningText:(NSString *)tipsText;

// 更新 手机号输入框Tips信息
- (void)updatePhoneTips:(NSString *)tipsText;
- (void)updatePhoneTipsWithWarningText:(NSString *)tipsText;
// 展现第二步绑卡前置相关view
- (BOOL)layoutFrontSecondStepBindCard:(CJPayMemCardBinResponse *)response;
- (void)layoutAuthTipsView;
- (void)showOCRButton:(BOOL)show;

@optional
- (void)updateCardTipsWithNormalText:(NSString *)tipsText;

@end

NS_ASSUME_NONNULL_END
