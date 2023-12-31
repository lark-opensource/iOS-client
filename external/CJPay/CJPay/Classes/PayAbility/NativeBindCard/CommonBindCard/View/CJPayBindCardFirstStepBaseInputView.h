//
//  CJPayBindCardFirstStepBaseInputView.h
//  Pods
//
//  Created by renqiang on 2021/9/10.
//

#import <UIKit/UIKit.h>
#import "CJPayBindCardFirstStepInputProtocol.h"
#import "CJPayBindCardPageBaseModel.h"

@class CJPayBindCardHeaderView;
@class CJPayBindCardFirstStepCardTipView;
@class CJPayCardOCRResultModel;
@class CJPayCenterTextFieldContainer;
@class CJPayBindCardFirstStepPhoneTipView;
@class CJPayBindCardAuthPhoneTipsView;
@class CJPayCommonProtocolView;
@class CJPayMemCardBinResponse;
@class CJPayStyleButton;
@class CJPayMemAgreementModel;
@class CJPayMemBankInfoModel;
@class CJPayBindCardFirstStepOCRView;
@class CJPayMemBankSupportListResponse;
@class CJPayUserInfo;
@class CJPayBindCardRecommendBankView;
@protocol CJPayCustomTextFieldContainerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface BDPayBindCardFirstStepBaseInputDataModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) BOOL isCertification;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSString *voucherBankStr;
@property (nonatomic, copy) NSString *voucherMsgStr;
@property (nonatomic, copy) NSString *firstStepMainTitle;

@end

@interface CJPayBindCardFirstStepBaseInputView : UIView<CJPayBindCardFirstStepInputProtocol>

#pragma mark - model
@property (nonatomic, strong) BDPayBindCardFirstStepBaseInputDataModel *dataModel;

#pragma mark - view
@property (nonatomic, strong) CJPayBindCardHeaderView *headerView;
@property (nonatomic, strong) CJPayBindCardFirstStepCardTipView *cardTipView;
@property (nonatomic, strong) CJPayCenterTextFieldContainer *cardNumContainer;
@property (nonatomic, strong) UIImageView *cardImgView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) CJPayBindCardFirstStepOCRView *ocrButtonView;
@property (nonatomic, strong) CJPayBindCardRecommendBankView *recommendBankView;

// 老用户第二部绑卡流程前置
@property (nonatomic, strong) CJPayCenterTextFieldContainer *phoneContainer;
@property (nonatomic, strong) CJPayBindCardFirstStepPhoneTipView *phoneTipView;
@property (nonatomic, strong) CJPayBindCardAuthPhoneTipsView *authPhoneTipsView;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;

#pragma mark - block
@property (nonatomic, copy) void(^didFrontSecondStepBindCardAppearBlock)(void);
// authButton
@property (nonatomic, copy) void(^didAuthButtonAppearBlock)(void);
@property (nonatomic, copy) void(^didClickAgreeAuthButtonBlock)(void);
@property (nonatomic, copy) void(^didClickCloseAuthButtonBlock)(void);
@property (nonatomic, copy) void(^didClickOCRButtonBlock)(void);
@property (nonatomic, copy) void(^didClickProtocolBlock)(NSArray<CJPayMemAgreementModel *> *agreements);
// nextButton
@property (nonatomic, copy) void(^didNextButtonClickBlock)(void);

#pragma mark - delegate
@property (nonatomic, weak) id<CJPayCustomTextFieldContainerDelegate> delegate;

#pragma mark - method
+ (NSArray <NSString *>*)dataModelKey;
- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
