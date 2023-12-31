// Copyright 2019 The Lynx Authors. All rights reserved.
//
//  LynxTextShadow.h
//  Lynx
//
//  Created by bytedance on 2020/2/20.
//

#import <Foundation/Foundation.h>
#import "LynxBoxShadowManager.h"
#import "LynxConverter.h"

NS_ASSUME_NONNULL_BEGIN
@class LynxUI;
@interface LynxConverter (NSShadow)
+ (NSShadow *)toNSShadow:(NSArray<LynxBoxShadow *> *)shadowArr;
@end

NS_ASSUME_NONNULL_END
