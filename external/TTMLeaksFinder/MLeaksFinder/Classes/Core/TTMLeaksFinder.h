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

#import "TTMLeaksConfig.h"
@class FBObjectGraphConfiguration;

extern NSString * const kTTMLeaksFinderLeakNotification;

@interface TTMLeaksFinder : NSObject

/*
 * MLeaksFinder的版本号
 */
+ (NSString *)version;

/*
 * 启动检测，参数不能为空
 */
+ (void)startDetectMemoryLeakWithConfig:(TTMLeaksConfig *)config;

/*
 * 停止检测
 */
+ (void)stopDetectMemoryLeak;

/*
 * 当前配置，为空表示停止检测状态
 */
+ (TTMLeaksConfig *)memoryLeaksConfig;

/*
* 手动触发检测
*/
+ (void)manualCheckRootObject:(id)rootObject;

@end

/*
 * 检测到内存泄漏时发出的通知
 * 不再维护，建议使用 kTTMLeaksFinderLeakNotification
 */
__deprecated_msg("use kTTMLeaksFinderLeakNotification instead")
extern NSString * const kTTMLeaksFinderFindMemoryLeakNotification;



@interface TTMLeaksFinder(Private)

+ (void)updateMemoryLeakConfig;
+ (NSMutableSet<Class> *)classNamesWhitelist;

@end
