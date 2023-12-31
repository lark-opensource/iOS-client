//
//  HTSServiceInterceptor.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2020/09/01.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTSServiceInterceptor<NSObject>

+ (BOOL)shouldIgnoreProtocol:(Protocol *)protocol;

+ (BOOL)shouldIgnoreService:(Class)cls;

@end
