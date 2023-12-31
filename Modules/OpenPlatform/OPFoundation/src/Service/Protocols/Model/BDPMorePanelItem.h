//
//  BDPMorePanelItem.h
//  Timor
//
//  Created by liuxiangxin on 2019/9/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class BDPMorePanelItem;

typedef void(^BDPMorePanelItemAction)(BDPMorePanelItem * _Nonnull item);

typedef NS_ENUM(NSInteger, BDPMorePanelItemType) {
    BDPMorePanelItemTypeShare = 0,
    /// 多任务(浮窗)
    BDPMorePanelItemTypeMultiTask,
    BDPMorePanelItemTypeCommonApp,
    BDPMorePanelItemTypeBot,
    BDPMorePanelItemTypeHome,
    BDPMorePanelItemTypeSetting,
    BDPMorePanelItemTypeFeedback,
    BDPMorePanelItemTypeAbout,
    BDPMorePanelItemTypeDebug,
    BDPMorePanelItemTypeLarkDebug,
    BDPMorePanelItemTypeCustom,
};

@interface BDPMorePanelItem : NSObject

/// item的显示名称
@property (nonatomic, copy, readonly, nonnull) NSString *name;
/// 显示的icon的image
///
/// 如果icon为nil， 会尝试使用iconURL来加载icon
@property (nonatomic, strong, readonly, nullable) UIImage *icon;
/// 显示的icon的url
///
/// 只有在icon为nil时才会尝试使用该url来加载icon
@property (nonatomic, copy, readonly,  nullable) NSURL *iconURL;
/// 类型
@property (nonatomic, assign, readonly) BDPMorePanelItemType type;
/// icon的点击回调。
///
/// 用户点击的时候会被调用
@property (nonatomic, copy, readonly, nullable) BDPMorePanelItemAction action;
/// 红点数，如果为0，则不展示
@property (nonatomic, assign, readonly) NSUInteger badgeNum;

+ (instancetype _Nonnull )itemWithName:(NSString *_Nullable)name
                               iconURL:(NSURL *_Nullable)iconURL
                                action:(BDPMorePanelItemAction _Nullable )action;

+ (instancetype _Nonnull )itemWithName:(NSString *_Nullable)name
                                  icon:(UIImage *_Nullable)icon
                              badgeNum:(NSUInteger)badgeNum
                                action:(BDPMorePanelItemAction _Nullable )action;

- (instancetype _Nonnull )initWithType:(BDPMorePanelItemType)type
                                  name:(NSString *)name
                                  icon:(UIImage *)icon
                               iconURL:(NSURL *)iconURL
                              badgeNum:(NSUInteger)badgeNum
                                action:(BDPMorePanelItemAction)action;

- (instancetype _Nonnull )initWithType:(BDPMorePanelItemType)type
                                  name:(NSString *_Nullable)name
                                  icon:(UIImage *_Nullable)icon
                               iconURL:(NSURL *_Nullable)iconURL
                                action:(BDPMorePanelItemAction _Nullable)action;

- (void)updateAction:(BDPMorePanelItemAction _Nullable)action;

@end
