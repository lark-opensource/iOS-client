//
//  LarkPageIn.m
//  Lark
//
//  Created by huanglx on 2022/12/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

#import "LarkPageIn.h"
#import <Jato/BDJTPageInPreloader.h>

// lint:disable lark_storage_check - 不涉及业务/用户、使用时机非常早，不做存储检查

@implementation LarkPageIn
+ (void)load {
    //开始预加载
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"page_in_preloading_enable"]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:[self VMFilePath]]){
            bdjt_startPreloadIfEnabled([self VMFilePath]);
        }
    }
}

// 小版本号作为预加载文件名
+ (NSString *)VMFileName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] ?: @"vm_page_fault";
}

+ (NSString *)VMFilePath {
    NSString *libDirPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libDirPath stringByAppendingPathComponent:[self VMFileName]];
}

// settings 更新后，及时设置下次预加载的策略
+ (void)updateBySettings:(bool)enable andFilePath:(NSString *)geckoPath andStrategy:(NSUInteger)strategy{
    if (!enable) {
        return;
    }
    //更新预加载文件
    NSString *filePath = [self VMFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filePath]) {
        if ([fm fileExistsAtPath:geckoPath]) {
            [fm copyItemAtPath:geckoPath toPath:filePath error:nil];
        }
    }
    if (![fm fileExistsAtPath:filePath]) {
        return;
    }
    //更新配置策略
    bdjt_setupPreloadForNextLaunch(strategy);
}

@end

