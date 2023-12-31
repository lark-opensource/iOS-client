//
//  BDPTabBarPageController.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/27.
//

#import <UIKit/UIKit.h>

#import <OPFoundation/BDPUniqueID.h>
#import "BDPTask.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDPTabBarImageSizeString;

@class BDPAppPageURL;
@class OPContainerContext;

@interface BDPTabBarPageController : UITabBarController

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                        delegate:(id<UITabBarControllerDelegate>)delegate
                containerContext:(OPContainerContext *)containerContext;

- (void)setTabBarItem:(NSInteger)index text:(NSString *)text iconPath:(NSString *)iconPath selectedIconPath:(NSString *)selectedIconPath completion:(void (^)(BOOL success))completion;
- (void)setTabBarStyle:(NSString * _Nullable)textColor textSelectedColor:(NSString * _Nullable)textSelectedColor backgroundColor:(NSString * _Nullable)backgroundColor borderStyle:(NSString * _Nullable)borderStyle borderColor:(NSString * _Nullable)borderColor completion:(void (^)(BOOL))completion;
- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(nullable void (^)(BOOL))completion;
- (void)removeTabBarItem:(NSString * _Nullable)pagePath completion:(void (^)(BOOL success, NSString * message, int callBackCode))completion;
- (void)addTabBarItem:(NSInteger)index pagePath:(NSString * _Nullable)pagePath text:(NSString * _Nullable)text dark:(NSDictionary * _Nullable)dark light:(NSDictionary * _Nullable)light completion:(void (^)(BOOL success, NSString * message, int callBackCode))completion;

/// 强制更新tabbar的限制隐藏，UIKit在切换是自动调整了该状态，需要主动再重新触发
- (void)temporaryHiddenAndRecover;

/// 新增静态方法，输入appPageController，输出此page中的tabBarController，如果不存在则输出nil
+ (nullable BDPTabBarPageController *)getTabBarVCForAppPageController:(BDPAppPageController *) appPageController;

/// 定义BDPTabBarController的三种状态
typedef NS_ENUM(NSInteger, TabBarStatus) {
    /// 小程序并不包含tabBar
    TabBarStatusTypeNoTabBar = 0,
    /// 小程序包含tabBar，但是当前页面tabBar并没有初始化
    TabBarStatusTypeNotReady = 1,
    /// 小程序包含tabBar并且tabBar已经初始化完毕
    TabBarStatusTypeReady = 2,
};
/// 新增静态方法，输入小程序BDPtask、appPageController，输出此时tabBar的状态
+ (TabBarStatus)getTabBarVCStatusWithTask:(nullable BDPTask *)task forPagePath:(nullable NSString *)pagePath;

@end

NS_ASSUME_NONNULL_END
