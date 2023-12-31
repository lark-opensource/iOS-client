//
//  TMABrightness.h
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMABrightness : NSObject

/** 调用单例记录播放状态是否锁定屏幕方向*/
@property (nonatomic, assign) BOOL     isLockScreen;
@property (nonatomic, assign) BOOL     isStatusBarHidden;
/** 是否是横屏状态 */
@property (nonatomic, assign) BOOL     isLandscape;

+ (instancetype)sharedBrightness;

@end

NS_ASSUME_NONNULL_END
