//
//  CJPayQuickBindCardTypeChooseView.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CardTypeChooseViewNextButtonClickBlock)(void);

@class CJPayQuickBindCardModel;
@class CJPayStyleButton;
@class CJPayCommonProtocolView;
@interface CJPayQuickBindCardTypeChooseView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) CJPayCommonProtocolView *protocolView;

@property (nonatomic, copy) CardTypeChooseViewNextButtonClickBlock confirmButtonClickBlock;
@property (nonatomic, copy) void(^didSelectedCardTypeBlock)(void);
@property (nonatomic, copy) void(^didSelectedAddOtherCardBlock)(void);
@property (nonatomic, copy) void(^inputCardClickBlock)(NSString *voucherStr, NSString *cardType);//跳转绑卡首页

- (void)reloadWithQuickBindCardModel:(CJPayQuickBindCardModel *)quickBindCardModel;
- (NSString *)currentSelectedCardType;
- (NSString *)currentSelectedCardVoucher;
- (void) updateUIWithoutProtocol;

@end

NS_ASSUME_NONNULL_END
