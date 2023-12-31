//
//  CJPayCustomTextFieldContainer.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import <UIKit/UIKit.h>

#import "CJPayCustomTextField.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCustomRightView;

typedef NS_ENUM(NSUInteger, CJPayTextFieldType) {
    CJPayTextFieldTypeBankCard = 0,
    CJPayTextFieldTypeIdentity = 1,
    CJPayTextFieldTypePhone = 2,
    CJPayTextFieldTypeName = 3
};

typedef NS_ENUM(NSUInteger, CJPayKeyBoardType) {
    CJPayKeyBoardTypeCustomNumOnly = 0, // 自定义键盘 仅数字
    CJPayKeyBoardTypeCustomXEnable = 1, // 自定义键盘 含有x
    CJPayKeyBoardTypeSystomDefault = 2  // 系统默认键盘
};

typedef NS_ENUM(NSUInteger, CJPayContainerStyle) {
    CJPayTextFieldDefault = 0,
    CJPayTextFieldQuickBindAuth = 1,
    CJPayTextFieldBindCardFirstStep = 2
};

typedef NS_ENUM(NSUInteger, CJPayCustomTextFieldContainerStyle) {
    CJPayCustomTextFieldContainerStyleWhite = 0,
    CJPayCustomTextFieldContainerStyleWhiteAndBottomTips = 2
};

@interface CJPayCustomTextFieldContainer : UIView

@property (nonatomic, strong, readonly) CJPayCustomTextField *textField;
@property (nonatomic, copy) NSString *customInputTitle;

#pragma mark - config
@property (nonatomic, strong) UIColor *cursorColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *warningTitleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat textFiledRightPadding;
// 实例化以后设置该属性重置键盘类型
@property (nonatomic, assign) CJPayKeyBoardType keyBoardType;

#pragma mark - flag
// 实例化以后设置该属性设置键盘是否支持点击完成关闭
@property (nonatomic, assign) BOOL isKeyBoardSupportEasyClose;

#pragma mark - data
@property (nonatomic, copy) NSString *placeHolderText;
@property (nonatomic, copy) NSString *subTitleText;
// 实例化以后设置该属性可以添加帮助按钮
@property (nonatomic, copy) NSString *infoContentStr;

#pragma mark - block
@property (nonatomic, copy) void(^infoClickBlock)(void);

- (instancetype)initWithFrame:(CGRect)frame
                textFieldType:(CJPayTextFieldType)textFieldType;
- (instancetype)initWithFrame:(CGRect)frame textFieldType:(CJPayTextFieldType)textFieldType style:(CJPayCustomTextFieldContainerStyle)containerStyle;


- (void)setupUI;
// 更新错误信息
- (void)updateTips:(NSString *)tipsText;
// 是否有提示
- (BOOL)hasTipsText;
// 预填信息
- (void)preFillText:(NSString *)text;
// 清除文本
- (void)clearText;
// 获取键盘高度
- (CGFloat)getKeyBoardHeight;

- (void)textFieldBeginEditAnimation;
- (void)textFieldEndEditAnimation;

@end

@protocol CJPayCustomTextFieldContainerDelegate <NSObject>

@optional
- (void)textFieldBeginEdit:(CJPayCustomTextFieldContainer *)textContainer;
- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer;
- (void)textFieldWillClear:(CJPayCustomTextFieldContainer *)textContainer;
- (void)textFieldDidClear:(CJPayCustomTextFieldContainer *)textContainer;
- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end

@interface CJPayCustomTextFieldContainer ()

#pragma mark - view
@property (nonatomic, strong) CJPayCustomTextField *textField;
@property (nonatomic, strong) UILabel *placeHolderLabel;
@property (nonatomic, strong) CJPayCustomRightView *customClearView;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, weak) id<CJPayCustomTextFieldContainerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END
