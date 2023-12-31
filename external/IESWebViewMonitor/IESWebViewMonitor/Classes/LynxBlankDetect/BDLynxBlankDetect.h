//
//  BDLynxBlankDetect.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/5/21.
//

#import <Foundation/Foundation.h>

@class LynxView;

NS_ASSUME_NONNULL_BEGIN

@protocol BDHMLynxBlankListenerDelegate <NSObject>

@optional
- (void)bdhmLynxBlankResult:(LynxView *)lynxView
        effectivePercentage:(float)percentage
                   costTime:(long)costTime;

@end

@interface BDLynxBlankDetect : NSObject

+ (float)startCheckWithView:(UIView *)view allowListBlcok:(BOOL(^)(UIView*))allowListBlock;

@end

@interface UIView (BDLynxBlankDetect)

@property(nonatomic, strong, readonly) NSHashTable *bdhm_blankListeners;

/// 为当前 LynxView 增加白屏回调监听 (not thread safe)
/// @param listener 监听对象 (弱引用)
- (void)bdhm_addLynxBlankListener:(id<BDHMLynxBlankListenerDelegate>)listener;

/// 移除当前 LynxView 的白屏回调监听 (not thread safe)
/// @param listener 监听对象
- (void)bdhm_removeLynxBlankListner:(id<BDHMLynxBlankListenerDelegate>)listener;

// 自动触发的方式，触发时机在removeFromSuperView
- (void)switchOnAutoCheckBlank:(BOOL)isOn lynxView:(LynxView *)lynxView;

// 手动触发的方式
- (float)checkWithAllowListBlock:(BOOL(^)(UIView*))allowListBlock lynxView:(LynxView *)lynxView;

@end

NS_ASSUME_NONNULL_END
