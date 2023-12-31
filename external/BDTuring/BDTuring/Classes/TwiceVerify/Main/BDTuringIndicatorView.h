//
//  BDTuringIndicatorView.h
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringIndicatorView;
typedef void (^DismissHandler)(BOOL isUserDismiss);

typedef NS_ENUM(NSInteger, BDTuringIndicatorViewStyle)
{
    BDTuringIndicatorViewStyleImage = 0,      //icon+文字样式
    BDTuringIndicatorViewStyleWaitingView     //转等待提示+文字样式
};


@interface BDTuringIndicatorView : UIView


/**
 *  指示器是否显示手动dismiss按钮，默认NO
 */
@property(nonatomic, assign) BOOL showDismissButton;
/**
 *  指示器是否一定时间后自动消失，默认YES
 *  @Attention 需要控制指示器更新text或icon时，需要设置为NO
 */
@property(nonatomic, assign) BOOL autoDismiss;
@property(nonatomic, assign) NSTimeInterval dismissDelay;

@property(nonatomic, assign) NSTimeInterval duration;

#pragma mark - Instance initializer

/**
 *  创建实例指示器，可显示在指定view上，生命周期跟随view
 *
 *  @param style              指示器类型，不可同时显示icon和waitingView
 *  @param indicatorText      tip文字，可为空
 *  @param indicatorImage     icon图片
 *  @param handler            指示器消失后的处理block
 *
 *  @return 指示器实例
 */
- (nonnull instancetype)initWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                                 indicatorText:(nullable NSString *)indicatorText
                                indicatorImage:(nullable UIImage *)indicatorImage
                                dismissHandler:(nullable DismissHandler)handler;


/**
 *  创建实例指示器，可显示在指定view上，生命周期跟随view
 *
 *  @param style              指示器类型，不可同时显示icon和waitingView
 *  @param indicatorText      tip文字，可为空
 *  @param indicatorImage     icon图片
 *  @param maxLine            最大行数
 *  @param handler            指示器消失后的处理block
 *
 *  @return 指示器实例
 */
- (nonnull instancetype)initWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                                 indicatorText:(NSString *)indicatorText
                                indicatorImage:(UIImage *)indicatorImage
                                       maxLine:(NSInteger)maxLine
                                dismissHandler:(DismissHandler)handler;
/**
 *  展示指示器
 *
 *  @param parentView 展示指示器的父superView
 */
- (void)showFromParentView:(nullable UIView *)parentView;

/**
 *  展示指示器
 *
 *  @param parentView 展示指示器的父superView
 *  @param offset     相对父superView的偏移量
 */
- (void)showFromParentView:(nullable UIView *)parentView offset:(UIOffset)offset;

/**
 *  手动销毁指示器，通常在autoDismiss设为NO后使用
 */
- (void)dismissFromParentView;

/**
 *  更新指示器tip文字
 *
 *  @param updateIndicatorText 更新后要显示的tip文字
 *  @param shouldRemoveWaitingView 如果指示器类型是BDTuringIndicatorViewStyleWaitingView，是否需要停止并移除
 */
- (void)updateIndicatorWithText:(nullable NSString *)updateIndicatorText
        shouldRemoveWaitingView:(BOOL)shouldRemoveWaitingView;

/**
 *  更新指示器iconImage，同时BDTuringIndicatorViewStyle强制更新为BDTuringIndicatorViewStyleImage
 *
 *  @param updateIndicatorImage 更新后要显示的iconImage
 */
- (void)updateIndicatorWithImage:(nullable UIImage *)updateIndicatorImage;
#pragma mark - Class initializer

/**
 *  创建便捷指示器，并显示在keyWindow（如果有，否则创建新的window）上
 *
 *  @param style 指示器类型，不可同时显示icon和waitingView
 *  @param indicatorText tip文字，可为空
 *  @param indicatorImage icon图片
 *  @param autoDismiss 指示器是否一定时间后自动消失
 *  @param handler 指示器消失后的处理block
 *  @Attention  autoDismiss建议设为YES，需要设为NO时建议使用实例构造器
 *              不显示dismissButton
 */
+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler;

/**
 *  创建便捷指示器，并显示在keyWindow（如果有，否则创建新的window）上
 *
 *  @param style 指示器类型，不可同时显示icon和waitingView
 *  @param indicatorText tip文字，可为空
 *  @param indicatorImage icon图片
 *  @param maxLine  最大行数
 *  @param autoDismiss 指示器是否一定时间后自动消失
 *  @param handler 指示器消失后的处理block
 *  @Attention  autoDismiss建议设为YES，需要设为NO时建议使用实例构造器
 *              不显示dismissButton
 */
+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler;

+ (void)showWithIndicatorStyle:(BDTuringIndicatorViewStyle)style
                 indicatorText:(nullable NSString *)indicatorText
                indicatorImage:(nullable UIImage *)indicatorImage
                       maxLine:(NSInteger)maxLine
                 expectedWidth:(CGFloat)expectedWidth
                   autoDismiss:(BOOL)autoDismiss
                dismissHandler:(nullable DismissHandler)handler;
/**
 *  强制销毁所有window上的所有指示器
 */
+ (void)dismissIndicators;
+ (void)showIndicatorForTextMessage:(nullable NSString *)textStr;

@end

static inline BOOL BDTuringShown(UIView  * _Nonnull view) {
    return !view.hidden;
}

NS_ASSUME_NONNULL_END
