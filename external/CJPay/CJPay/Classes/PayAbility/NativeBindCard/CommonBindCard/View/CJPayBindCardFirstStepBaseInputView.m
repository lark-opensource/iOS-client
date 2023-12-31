//
//  CJPayBindCardFirstStepBaseInputView.m
//  Pods
//
//  Created by renqiang on 2021/9/10.
//

#import "CJPayBindCardFirstStepBaseInputView.h"
#import "CJPayBindCardHeaderView.h"
#import "CJPayBindCardNumberViewModel.h"
#import "CJPayBindCardFirstStepCardTipView.h"
#import "CJPayCenterTextFieldContainer.h"
#import "CJPayBindCardFirstStepOCRView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayBindCardFirstStepPhoneTipView.h"
#import "CJPayBindCardAuthPhoneTipsView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayUserInfo.h"
#import "CJPayBindCardRecommendBankView.h"

@implementation BDPayBindCardFirstStepBaseInputDataModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"voucherBankStr" : CJPayBindCardShareDataKeyVoucherBankStr,
        @"voucherMsgStr" : CJPayBindCardShareDataKeyVoucherMsgStr,
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBindCardFirstStepBaseInputView () <CJPayCustomTextFieldContainerDelegate>

#pragma mark - flag
@property (nonatomic, assign) BOOL isFrontSecondStepBindCardShown;
@property (nonatomic, assign) BOOL isCloseAuthTips;

@end

@implementation CJPayBindCardFirstStepBaseInputView

+ (NSArray <NSString *>*)dataModelKey {
    return [BDPayBindCardFirstStepBaseInputDataModel keysOfParams];
}

- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict {
    if (self = [super init]) {
        if (dict.count > 0) {
            self.dataModel = [[BDPayBindCardFirstStepBaseInputDataModel alloc] initWithDictionary:dict error:nil];
        }
    }
    return self;
}

- (void)updatePhoneTips:(NSString *)tipsText {
    [self.phoneTipView updateTips:tipsText];
}

- (void)updatePhoneTipsWithWarningText:(NSString *)tipsText {
    [self.phoneContainer showBorder:Check_ValidString(tipsText)];
    [self.phoneTipView updateTipsWithWarningText:tipsText];
}

- (void)layoutAuthTipsView {
    if ([self p_isShowAuthPhoneTips]) {
        [UIView animateWithDuration:0.1 animations:^{
            self.authPhoneTipsView.alpha = 1;
        }];
        CJ_CALL_BLOCK(self.didAuthButtonAppearBlock);
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            self.authPhoneTipsView.alpha = 0;
        }];
    }
}

- (void)showOCRButton:(BOOL)show {
    self.ocrButtonView.hidden = !show;
}

- (BOOL)layoutFrontSecondStepBindCard:(nonnull CJPayMemCardBinResponse *)response {
    // 协议方法，子类实现
    return NO;
}


- (void)updateCardNumContainerPlaceHolderTextWithName:(nonnull NSString *)name {
    // 协议方法，子类实现
}


- (void)updateCardTipsMemBankInfoModel:(nonnull CJPayMemBankInfoModel *)model {
    // 协议方法，子类实现
}


- (void)updateCardTipsWithWarningText:(nonnull NSString *)tipsText {
    // 协议方法，子类实现
}


#pragma mark private method
- (void)p_nextButtonClick {
    CJ_CALL_BLOCK(self.didNextButtonClickBlock);
}

- (void)p_ocrButtonClick {
    CJ_CALL_BLOCK(self.didClickOCRButtonBlock);
}

- (BOOL)p_isShowAuthPhoneTips {
    return [self p_shouldShowAuthTipsView] &&
    [self p_isSupportAuthPhoneNumber] &&
    [self.phoneContainer.textField isFirstResponder] &&
    !self.isCloseAuthTips;
}

- (BOOL)p_shouldShowAuthTipsView {
    NSString *mobileStr = self.dataModel.userInfo.uidMobileMask;
    NSString *inputStr = self.phoneContainer.textField.text;
    
    if (!Check_ValidString(mobileStr)) {
        return NO;
    }
    if (!Check_ValidString(inputStr)) {
        return YES;
    }
    return [mobileStr hasPrefix:inputStr];
}

- (BOOL)p_isSupportAuthPhoneNumber {
    return Check_ValidString(self.dataModel.userInfo.uidMobileMask) &&
    !Check_ValidString(self.dataModel.userInfo.mobile);
}

- (NSDictionary *)genDictionaryByKeys:(NSArray <NSString *>*)keys fromViewModel:(BDPayBindCardFirstStepBaseInputDataModel *)viewModel {
    if (keys == nil || keys.count == 0 || viewModel == nil) {
        return nil;
    }
    
    NSDictionary *allSharedDataDict = [viewModel toDictionary];
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict cj_objectForKey:key]) {
            [returnDict cj_setObject:[allSharedDataDict cj_objectForKey:key] forKey:key];
        }
    }];
    
    return [returnDict copy];
}

#pragma mark - setter & getter

- (CJPayBindCardHeaderView *)headerView {
    if (!_headerView) {
        NSArray *needParams = [CJPayBindCardHeaderView dataModelKey];
        NSDictionary *paramsDict = [self genDictionaryByKeys:needParams fromViewModel:self.dataModel];
        _headerView = [[CJPayBindCardHeaderView alloc] initWithBindCardDictonary:paramsDict
                                                                     isFirstStep:YES];
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
        _headerView.clipsToBounds = YES;
    }
    return _headerView;
}

- (CJPayBindCardFirstStepCardTipView *)cardTipView {
    if (!_cardTipView) {
        _cardTipView = [CJPayBindCardFirstStepCardTipView new];
        _cardTipView.translatesAutoresizingMaskIntoConstraints = NO;
        _cardTipView.hidden = YES;
    }
    return _cardTipView;
}

- (CJPayBindCardRecommendBankView *)recommendBankView {
    if (!_recommendBankView) {
        _recommendBankView = [CJPayBindCardRecommendBankView new];
        _recommendBankView.hidden = YES;
    }
    return _recommendBankView;
}

- (CJPayCenterTextFieldContainer *)cardNumContainer {
    if (!_cardNumContainer) {
        _cardNumContainer = [[CJPayCenterTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypeBankCard type:CJPayTextFieldBindCardFirstStep];
        _cardNumContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _cardNumContainer.delegate = self;
        _cardNumContainer.isKeyBoardSupportEasyClose = YES;
        _cardNumContainer.placeHolderLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _cardNumContainer;
}

- (CJPayBindCardFirstStepOCRView *)ocrButtonView {
    if (!_ocrButtonView) {
        _ocrButtonView = [CJPayBindCardFirstStepOCRView new];
        @CJWeakify(self)
        _ocrButtonView.didOCRButtonClickBlock = ^{
            @CJStrongify(self)
            [self p_ocrButtonClick];
        };
    }
    return _ocrButtonView;
}

- (UIImageView *)cardImgView {
    if (!_cardImgView) {
        _cardImgView = [UIImageView new];
    }
    return _cardImgView;
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        _nextStepButton = [[CJPayStyleButton alloc] init];
        [_nextStepButton setTitle:CJPayLocalizedStr(@"下一步") forState:UIControlStateNormal];
        _nextStepButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _nextStepButton.cjEventInterval = 2;
        _nextStepButton.layer.masksToBounds = YES;
        _nextStepButton.layer.cornerRadius = 2;
        _nextStepButton.clipsToBounds = YES;
        _nextStepButton.translatesAutoresizingMaskIntoConstraints = NO;
        _nextStepButton.enabled = NO;
        [_nextStepButton addTarget:self action:@selector(p_nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextStepButton;
}

- (CJPayCenterTextFieldContainer *)phoneContainer {
    if (!_phoneContainer) {
        _phoneContainer = [[CJPayCenterTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypePhone type:CJPayTextFieldBindCardFirstStep];
        _phoneContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _phoneContainer.clipsToBounds = YES;
        _phoneContainer.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
        _phoneContainer.delegate = self;
    }
    return _phoneContainer;
}

- (CJPayBindCardFirstStepPhoneTipView *)phoneTipView {
    if (!_phoneTipView) {
        _phoneTipView = [[CJPayBindCardFirstStepPhoneTipView alloc] init];
        _phoneTipView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _phoneTipView;
}

- (CJPayBindCardAuthPhoneTipsView *)authPhoneTipsView {
    if (!_authPhoneTipsView) {
        _authPhoneTipsView = [CJPayBindCardAuthPhoneTipsView new];
        [_authPhoneTipsView updatePhoneNumber:self.dataModel.userInfo.uidMobileMask];
        _authPhoneTipsView.alpha = 0;
        @CJWeakify(self)
        _authPhoneTipsView.clickAuthButtonBlock = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.didClickAgreeAuthButtonBlock);
        };
        
        _authPhoneTipsView.clickCloseButtonBlock = ^{
            @CJStrongify(self)
            
            self.isCloseAuthTips = YES;
            CJ_CALL_BLOCK(self.didClickCloseAuthButtonBlock);
        };
    }
    return _authPhoneTipsView;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.didClickProtocolBlock, agreements);
        };
    }
    return _protocolView;
}

@end
