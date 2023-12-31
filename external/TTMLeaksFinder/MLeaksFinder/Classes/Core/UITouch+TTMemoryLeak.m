/**
 * Tencent is pleased to support the open source community by making MLeaksFinder available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "UITouch+TTMemoryLeak.h"
#import <objc/runtime.h>
#import "TTMLUtils.h"

extern const void *const kTTLatestSenderKey;
const void *const kTTLatestSenderKey = &kTTLatestSenderKey;

@implementation UITouch (MemoryLeak)
//
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(setView:) withSEL:@selector(tt_swizzled_setView:)];
//    });
//}
//
//- (void)tt_swizzled_setView:(UIView *)view {
//    [self tt_swizzled_setView:view];
//    
//    if ([TTMLeaksFinder memoryLeaksConfig] && view) {
//        objc_setAssociatedObject([UIApplication sharedApplication],
//                                 kTTLatestSenderKey,
//                                 @((uintptr_t)view),
//                                 OBJC_ASSOCIATION_RETAIN);
//    }
//}

@end
