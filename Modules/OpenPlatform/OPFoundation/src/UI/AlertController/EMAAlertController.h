//
//  EMAAlertController.h
//  EEMicroAppSDK
//  支持自定义样式的 AlertController
//  Created by yinyuan on 2019/1/22.
//

#import <UIKit/UIKit.h>
#import "EMAAlertTextView.h"

/// 自定义的配置
@interface EMAAlertControllerConfig : NSObject

@property (nonatomic, strong) UIColor *lineColor;               // 分割线颜色
@property (nonatomic, assign) CGFloat lineWidth;                // 分割线宽度

@property (nonatomic, assign) CGFloat alertWidth;               // AlertView 宽度
@property (nonatomic, assign) CGFloat actionSheetWidth;         // ActionSheet 宽度
@property (nonatomic, assign) CGFloat actionSheetBottomMargin;  // ActionSheet 底部边距
@property (nonatomic, assign) CGFloat actionSheetCancelButtonTopMargin;  // ActionSheet 底部边距

@property (nonatomic, assign) UIEdgeInsets headerEdgeInsets;    // 头部面板周边距
@property (nonatomic, assign) UIEdgeInsets titleEdgeInsets;     // Title控件周边距
@property (nonatomic, assign) NSTextAlignment titleAligment;    // Title控件对齐方式
@property (nonatomic, assign) UIEdgeInsets messageEdgeInsets;   // Message控件周边距
@property (nonatomic, assign) UIEdgeInsets textviewEdgeInsets;  // Textview控件周边距
@property (nonatomic, assign) CGFloat headerItemSpaceMargin;    // 头部面板子控件间距
@property (nonatomic, assign) CGFloat actionButtonSpaceMargin;  // action button控件间距

@property (nonatomic, assign) CGFloat alertButtonHeight;        // Alert 按钮高度
@property (nonatomic, assign) CGFloat actionSheetButtonHeight;  // ActionSheet 按钮高度
@property (nonatomic, assign) CGFloat textviewHeight;           // Textview 高度

@property (nonatomic, assign) NSInteger textviewMaxLength;      // Textview 最大字符数
@property (nonatomic, strong) UIColor *textviewPlaceholderColor; // Textview placeholder 颜色
@property (nonatomic, strong) UIFont *textviewFont;             // Textview 字体
@property (nonatomic, strong) UIColor *textviewTextColor;        // Textview 字颜色

@property (nonatomic, assign) UIInterfaceOrientationMask supportedInterfaceOrientations;

@end

@class EMAAlertAction;
typedef void (^EMAAlertActionBlock)(EMAAlertAction *action);

@interface EMAAlertAction : UIAlertAction

+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(EMAAlertActionBlock)handler;

/// 支持自定义以下视图控件的样式
@property (nonatomic, strong, readonly) UIButton *titleButton;
@property (nonatomic, assign) UIEdgeInsets titleButtonEdgeInsets;

/// 支持设置lineView为自定义的view
@property (nonatomic, strong) UIView *lineView;

@end

@interface EMAAlertController : UIViewController

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title
                     textviewPlaceholder:(nullable NSString *)textviewPlaceholder
                          preferredStyle:(UIAlertControllerStyle)preferredStyle
                                  config:(EMAAlertControllerConfig *)config;

- (void)addAction:(EMAAlertAction *)action;
@property (nonatomic, readonly) NSArray<EMAAlertAction *> *actions;

@property (nonatomic, strong, nullable) EMAAlertAction *preferredAction NS_AVAILABLE_IOS(9_0);

- (void)addTextFieldWithConfigurationHandler:(void (^ __nullable)(UITextField *textField))configurationHandler;
@property (nullable, nonatomic, readonly) NSArray<UITextField *> *textFields;

@property (nonatomic, readonly) UIAlertControllerStyle preferredStyle;

#pragma mark - Customize

/// 支持自定义以下视图控件的样式
@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, strong, readonly) UIView *containerBackgroundView;

@property (nonatomic, strong, readonly) UIView *alertView;
@property (nonatomic, strong, readonly) UIView *alertViewBackgroundView;

@property (nonatomic, strong, readonly) UIView *actionSheetTopView;
@property (nonatomic, strong, readonly) UIView *actionSheetTopViewBackgroundView;

@property (nonatomic, strong, readonly) UIView *actionSheetCancelView;
@property (nonatomic, strong, readonly) UIView *actionSheetCancelViewBackgroundView;

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *messageLabel;
@property (nonatomic, strong, readonly) EMAAlertTextView *textview;

@property (nonatomic, strong, readonly) EMAAlertAction *currentHighlightedAction;  // 有preferredAction则就是preferredAction，没有preferredAction则是cancelAction

/// 支持指定样式配置
@property (nonatomic, strong, readonly) EMAAlertControllerConfig *config;

@property (nonatomic, strong, readonly) EMAAlertAction *customBgTapAction;   // 自定义空白区点击Action(可以是已经add的Action，也可以是其他未add的Action)，点击后会触发该action的事件

@property (nonatomic, copy) void (^doPresentAnimation)(EMAAlertController *alert, void(^completion)(BOOL finished));   // 自定义入场动画，动画完成后调用completion
@property (nonatomic, copy) void (^doDismissAnimation)(EMAAlertController *alert, void(^completion)(BOOL finished));   // 自定义出场动画，动画完成后调用completion

/// 在合适的时机修改内容或布局
@property (nonatomic, copy) void (^customBlockAfterViewUpdated)(EMAAlertController *alert);  // 当updateView完成后会调用，此处可以进行一些修改或布局调整
@property (nonatomic, copy) void (^customContentViewBlockWhenUpdateView)(EMAAlertController *alert, NSUInteger idx, UIView *contentView); // 在updateView中contentView布局更新完成后调用，此处可以进行一些修改或布局调整
@property (nonatomic, copy) void (^customActionBlockWhenUpdateView)(EMAAlertController *alert, EMAAlertAction *action);     // 在updateView中action布局更新完成后调用，此处可以进行一些修改或布局调整

/// 初始化时可指定配置
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle config:(EMAAlertControllerConfig *)config;

- (void)updateView; // 当修改了布局或者config后，你需要调用updateView来更新视图

#pragma mark - ContentView

/// 添加自定义的view
- (void)addContentView:(UIView *)contentView viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets;
- (void)insertContentView:(UIView *)contentView atIndex:(NSUInteger)index viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets;
@property (nullable, nonatomic, readonly) NSArray<UIView *> *contentViews;

/// 添加EMAAlertTextView
- (void)addTextViewWithConfigurationHandler:(void (^ __nullable)(EMAAlertTextView *textView))configurationHandler height:(CGFloat)height;
- (void)addTextViewWithConfigurationHandler:(void (^ __nullable)(EMAAlertTextView *textView))configurationHandler height:(CGFloat)height viewEdgeInsets:(UIEdgeInsets)viewEdgeInsets;
/// 添加UILabel
- (void)addLabelWithConfigurationHandler:(void (^ __nullable)(UILabel *label))configurationHandler;

/// 为ContainerView添加挂件
- (void)addWidgetView:(UIView *)widgetView;
@property (nullable, nonatomic, readonly) NSArray<UIView *> *widgetViews;

@end
