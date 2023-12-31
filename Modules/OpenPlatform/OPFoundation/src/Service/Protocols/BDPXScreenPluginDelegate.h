//
//  BDPXScreenPluginDelegate.h
//  Pods
//
//  Created by qianhongqiang on 2022/09/05.
//  Copyright © 2022 Bytedance.com. All rights reserved.
//

#ifndef BDPXScreenPluginDelegate_h
#define BDPXScreenPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDPXScreenPluginDelegate <BDPBasePluginDelegate>


/// 判断在启动到common初始化之间应用是否为半屏模式
/// @param uniqueID
- (BOOL)isXscreenModeWhileLaunchingForUniqueID:(BDPUniqueID *)uniqueID;


/// 判断在启动到common初始化之间应用的半屏样式
/// @param uniqueID
- (nullable NSString *)XScreenPresentationStyleWhileLaunchingForUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END

#endif /* BDPUIPluginDelegate_h */
