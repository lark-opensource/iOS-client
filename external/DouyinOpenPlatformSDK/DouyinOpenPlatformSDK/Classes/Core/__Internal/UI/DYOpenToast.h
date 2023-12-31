//
//  DYOpenToast.h
//  DouyinOpenPlatformSDK-ad006023
//
//  Created by arvitwu on 2022/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DYOpenToast;
typedef void(^DYOpenToastCompleteBlock)(void); // DYOpenToast 展示完成回调
typedef void(^DYOpenToastEverySecondBlock)(DYOpenToast *_Nonnull toastView, NSTimeInterval leftTime); // DYOpenToast 每秒回调

typedef NS_ENUM(NSInteger, ToastDisplayMode) {
    ToastDisplayMode_Release    = 0,
    ToastDisplayMode_Debug      = 1,
    ToastDisplayMode_Internal   = 2,
};

@class DYOpenToast;

// 此 Delegate 的目的是用于 Debug 模式的调试
@protocol DYOpenToastDebugDelegate <NSObject>
@optional
- (void)toastWillDisplay:(NSString *)toast;
- (void)toastDidDisplayed:(NSString *)toast;
- (void)toastWillDisappear:(NSString *)toast;
- (void)toastDidDisappear:(NSString *)toast;
- (void)toastDidCancel:(NSString *)toast andReason:(NSString *)reason;
@end

@interface DYOpenToastConfig : NSObject

/// 是否允许进行展示频率检查，如设置为NO，其他的frequence属性设置会失效
/// 默认为开启
@property (nonatomic, assign) BOOL frequenceCheckEnable;

/// 同样文案展示两次之间的需要的间隔时间, 单位：秒，默认 2 秒
@property (nonatomic, assign) CGFloat frequenceDisplayTimeGap;

/// 展示文案存储的上限，默认为 20 条
@property (nonatomic, assign) NSUInteger frequenceCacheCountLimit;

/// 展示模式
@property (nonatomic, assign) ToastDisplayMode displayMode;

/// 是否是调试模式，只有在 DebugMode 下才会调用 delgate 的方法
@property (nonatomic, assign) BOOL debugMode;

/// delegate
@property (nonatomic, weak) id<DYOpenToastDebugDelegate> delegate;

/// 频控白名单，如果在白名单里，不受频控限制
@property (nonatomic, strong) NSDictionary *frequenceWhiteList;

/// 文字字体
@property (nonatomic, strong) UIFont *font;

/// 是否黑暗模式，默认 NO
@property (nonatomic, assign) BOOL isDarkMode;

/// 生成默认配置
+ (DYOpenToastConfig *)defaultToastConfig;

@end

/// 具体去展示Toast的类
@interface DYOpenToast : UIView

/// 以 alert 方式显示 toast, 默认两秒
+ (void)showAlertToast:(NSString *)message completion:(void (^ _Nullable)(void))completion;
+ (void)showAlertToast:(nonnull NSString *)message duraion:(NSTimeInterval)duration completion:(void (^ __nullable)(void))completion;

/// DYOpenToast 的设置参数
/// @param config DYOpenToastConfig
+ (void)setConfig:(DYOpenToastConfig *)config;

/// 此接口仅在 ToastDisplayMode_Debug 模式会显示,通过 Config 进行设置
+ (void)debugToast:(NSString *)text;

/// 此接口在 ToastDisplayMode_Internal  或者 ToastDisplayMode_Debug 下会显示 toast, 通过 Config 进行设置
+ (void)internalToast:(NSString *)text;

/// 具体展示Toast的方法，调用就会展示，不指定 duraion 则默认展示 2 秒
+ (void)showToast:(NSString *_Nonnull)text;
+ (void)showToast:(NSString *_Nonnull)text completeBlock:(nullable DYOpenToastCompleteBlock)finishBlock;
+ (void)showToast:(NSString *_Nonnull)text duration:(NSTimeInterval)duration completeBlock:(nullable DYOpenToastCompleteBlock)finishBlock;
/// @param inView 为 nil 时默认取 UIWindow
+ (void)showToast:(NSString *_Nonnull)text inView:(UIView *_Nullable)inView duration:(NSTimeInterval)duration secondBlock:(DYOpenToastEverySecondBlock _Nullable)secondBlock completeBlock:(DYOpenToastCompleteBlock _Nullable)finishBlock;
+ (void)clean;
+ (void)showToastAndClean:(NSString *_Nonnull)text;
+ (void)showToastAndClean:(NSString *_Nonnull)text completeBlock:(nullable DYOpenToastCompleteBlock)finishBlock;
+ (void)showToastAndClean:(NSString *_Nonnull)text duration:(NSTimeInterval)duration completeBlock:(nullable DYOpenToastCompleteBlock)finishBlock;

/// 更新内容
- (void)updateText:(NSString *_Nullable)text;

@end

NS_ASSUME_NONNULL_END
