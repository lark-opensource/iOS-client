//
//  CJPaySafeKeyboard.h
//  CJPay
//
//  Created by 杨维 on 2018/10/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPaySafeKeyboardType) {
    CJPaySafeKeyboardTypeDefault,
    CJPaySafeKeyboardTypeIDCard,
    CJPaySafeKeyboardTypeDenoise,
    CJPaySafeKeyboardTypeDenoiseV2
};
static const NSInteger kButtonCompleteTag;
@class CJPayLocalThemeStyle;
@class CJPayStyleButton;
@interface CJPaySafeKeyboardStyleConfigModel: NSObject

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic, strong) UIColor *borderColor;                 // 按钮边框色
@property (nonatomic, strong) UIColor *gridBlankBackgroundColor;    // 按钮间隙背景色
@property (nonatomic, strong) UIColor *gridNormalColor;
@property (nonatomic, strong) UIColor *gridHighlightColor;
@property (nonatomic, strong) UIColor *deleteNormalColor;
@property (nonatomic, strong) UIColor *deleteHighlightColor;
@property (nonatomic, copy) NSString *deleteImageName;
@property (nonatomic, assign) CGFloat rowGap;                       // 行间距
@property (nonatomic, assign) CGFloat buttonCornerRadius;
@property (nonatomic, assign) UIEdgeInsets insets;

+ (instancetype)defaultModel;

+ (instancetype)modelWithType:(CJPaySafeKeyboardType)keyboardType;

@end


/**
 自定义键盘
 */
@interface CJPaySafeKeyboard : UIView

/**
 点击数字回调
 */
 @property (nonatomic, copy) void (^numberClickedBlock)(NSInteger number);

/**
 点击输入回调
 */
 @property (nonatomic, copy) void (^characterClickedBlock)(NSString *string);

/**
 点击删除回调
 */
@property (nonatomic, copy) void (^deleteClickedBlock)(void);

/**
 点击完成回调
 */
@property (nonatomic, copy) void (^completeClickedBlock)(void);

/**
 初始化，按顺序排列的数字键盘
 */
- (instancetype)initWithFrame:(CGRect)frame;

- (void)setupUI;

/**
 该方法用于自定义样式，使用预定义样式只需设置keyboardType，然后直接调用setupUI
 */
- (void)setupUIWithModel:(CJPaySafeKeyboardStyleConfigModel *)model;

@property (nonatomic, strong) CJPayLocalThemeStyle *themeStyle;

@property (nonatomic, assign) CJPaySafeKeyboardType keyboardType;

@property (nonatomic, strong, readonly) CJPaySafeKeyboardStyleConfigModel *styleConfigModel;

@end

NS_ASSUME_NONNULL_END
