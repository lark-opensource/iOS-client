//
//  BDPPluginApplication.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/26.
//

#import "BDPPluginBase.h"

@interface BDPPluginApplication : BDPPluginBase

BDP_EXPORT_HANDLER(getMenuButtonBoundingClientRect)     // 获取工具栏Rect(⚠️同步方法)

@end
