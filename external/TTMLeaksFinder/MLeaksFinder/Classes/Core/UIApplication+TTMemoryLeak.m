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

#import "UIApplication+TTMemoryLeak.h"
#import "TTMLUtils.h"
#import <objc/runtime.h>

extern const void *const kTTLatestSenderKey;

@implementation UIApplication (TTMemoryLeak)
//
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(sendAction:to:from:forEvent:) withSEL:@selector(tt_swizzled_sendAction:to:from:forEvent:)];
//    });
//}
//
//- (BOOL)tt_swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
//    if ([TTMLeaksFinder memoryLeaksConfig]) {
//        objc_setAssociatedObject(self, kTTLatestSenderKey, @((uintptr_t)sender), OBJC_ASSOCIATION_RETAIN);
//    }
//
//    return [self tt_swizzled_sendAction:action to:target from:sender forEvent:event];
//}

@end
