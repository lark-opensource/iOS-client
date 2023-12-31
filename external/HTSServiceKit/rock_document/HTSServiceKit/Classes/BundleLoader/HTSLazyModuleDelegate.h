//
//  HTSLazyModuleDelegate.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSMacro.h"

/// 注册一个Lazy Module，framework被懒加载的时候会出触发这个delegate
#define HTS_LAZY_MODULE(_classname_)\
__attribute((used, section(_HTS_SEGMENT "," _HTS_LAZY_DELEGATE_SECTION )))\
static const char * _HTS_UNIQUE_VAR = #_classname_;

NS_ASSUME_NONNULL_BEGIN

@protocol HTSLazyModuleDelegate <NSObject>

/// module被懒加载完成
- (void)lazyModuleDidLoad;

/// module将要被卸载
- (void)lazyModuleWillUnload;

@end

NS_ASSUME_NONNULL_END
