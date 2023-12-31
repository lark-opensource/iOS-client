//
//  CJPayCardUpdateView.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPayCardUpdateViewConfirmBlock)(void);

@class CJPayCustomTextFieldContainer;
@class CJPayBindCardProtocolView;
@class CJPayCardUpdateModel;
@class CJPayStyleButton;
@interface CJPayCardUpdateView : UIView

@property (nonatomic, copy) BDPayCardUpdateViewConfirmBlock confirmBlock;

@property (nonatomic, strong, readonly) CJPayCustomTextFieldContainer *phoneContainer;
@property (nonatomic, strong, readonly) CJPayBindCardProtocolView *protocolView;
@property (nonatomic, strong, readonly) CJPayStyleButton *nextStepButton;

- (void)updateWithBDPayCardUpdateModel:(CJPayCardUpdateModel *)model;

@end

NS_ASSUME_NONNULL_END
