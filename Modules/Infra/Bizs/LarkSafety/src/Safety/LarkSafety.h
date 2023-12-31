//
//  LarkSafety.h
//  LarkApp
//
//  Created by KT on 2019/7/18.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>

#pragma mark - 反调试
void AntiDebug(void);

#pragma mark - 反注入
void AntiDylibInject (const struct mach_header *mh, intptr_t vmaddr_slide);

NS_ASSUME_NONNULL_BEGIN

@interface LarkSafety : NSObject

@end

NS_ASSUME_NONNULL_END
