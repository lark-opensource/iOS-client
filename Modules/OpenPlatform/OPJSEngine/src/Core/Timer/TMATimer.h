//
//  TMATimer.h
//  Timor
//
//  Created by muhuai on 2017/12/6.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMATimer : NSObject

// setTimeout 平台实现，dispatch_queue方式
- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time callbackMainThread:(void(^)(void))callback;
- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time callbackQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback;

// setTimeout 平台实现，runloop方式
- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time inRunLoop:(NSRunLoop*)runloop callback:(void(^)(void))callback;

// clearTimeout 销毁
- (void)clearTimeout:(NSInteger)functionID;

// setInterval 平台实现，dispatch_queue方式
- (void)setInterval:(NSInteger)functionID time:(NSInteger)time callbackMainThread:(void(^)(void))callback;
- (void)setInterval:(NSInteger)functionID time:(NSInteger)time callbackQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback;

// setInterval 平台实现，runloop方式
- (void)setInterval:(NSInteger)functionID time:(NSInteger)time inRunLoop:(NSRunLoop*)runloop callback:(void(^)(void))callback;

// clearInterval 销毁
- (void)clearInterval:(NSInteger)functionID;
@end
