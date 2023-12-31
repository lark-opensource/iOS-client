//
//  CJPayAmountTextFieldContainer.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/10.
//

#import <UIKit/UIKit.h>
#import "CJPayAmountTextField.h"
#import "CJPayCustomRightView.h"
NS_ASSUME_NONNULL_BEGIN

@class CJPayDouyinKeyboard;
@protocol CJPayAmountTextFieldContainerDelegate;

@interface CJPayAmountTextFieldContainer : UIView
@property (nonatomic, strong) CJPayAmountTextField *textField;
@property (nonatomic, strong) CJPayCustomRightView *customClearView;
@property (nonatomic, weak) id<CJPayAmountTextFieldContainerDelegate> delegate;
@property (nonatomic, strong, readonly) CJPayDouyinKeyboard *safeKeyBoard;
@property (nonatomic, strong) UILabel *placeHolderLabel;

@property (nonatomic, strong) UIColor *cursorColor UI_APPEARANCE_SELECTOR;

- (double)amountValue;
- (NSString *)amountText;
- (void)setTextFieldPlaceHolderWith:(NSString *)placeHolderText;

@end

@protocol CJPayAmountTextFieldContainerDelegate <NSObject>

- (void)containerKeyBoardClick;

@optional
- (BOOL)textFieldShouldBeginEditing:(CJPayAmountTextFieldContainer *)textContainer;
- (void)textFieldBeginEdit:(CJPayAmountTextFieldContainer *)textContainer;
- (void)textFieldEndEdit:(CJPayAmountTextFieldContainer *)textContainer;
- (void)textFieldWillClear:(CJPayAmountTextFieldContainer *)textContainer;
- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayAmountTextFieldContainer *)textContainer;

- (void)textFieldTapGestureClick; // 手势点击响应

@end

NS_ASSUME_NONNULL_END
