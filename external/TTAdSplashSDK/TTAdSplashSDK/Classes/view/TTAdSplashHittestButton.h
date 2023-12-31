//
//  TTAdSplashHittestButton.h
//  TTAdSplashSDK
//
//  Created by resober on 2019/4/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashHittestHotspot : NSObject
/// 绑定的需要更改热区的视图。
@property (nonatomic, weak) UIView *target;
/// 额外的热区，对应上下左右，仅支持热区增大，热区减小不支持。
@property (nonatomic, assign) UIEdgeInsets extraHotspotInsets;
- (instancetype)initWithTarget:(UIView *)target extraHotspotInsets:(UIEdgeInsets)extraHotspotInsets;
@end

@interface TTAdSplashHittestButton : UIButton

/**
 刷新视图需要修改热区的视图单位，获取点击事件的优先级根据视图在hotspots中排列顺序决定

 @param hotspots 热区单位
 */
- (void)refreshHotspotWith:(NSArray<TTAdSplashHittestHotspot *> *)hotspots;
@end

NS_ASSUME_NONNULL_END
