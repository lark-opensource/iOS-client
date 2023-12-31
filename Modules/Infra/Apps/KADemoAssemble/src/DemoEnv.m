//
//  DemoEnv.m
//  KADemoAssemble
//
//  Created by Supeng on 2021/12/15.
//

#import "DemoEnv.h"
@import KATabInterface;
@import KAFileInterface;
#import <KADemoAssemble/KADemoAssemble-Swift.h>
#import "FileTabViewController.h"

@implementation DemoEnv

+(UIViewController*)rootViewController {

    TabBarController* controller = [[TabBarController alloc] initWithConfigs:[self allTabConfigs]];
    return [[UINavigationController alloc] initWithRootViewController:controller];
}

+(NSArray<KATabConfig*>*)allTabConfigs {
    NSArray* allConfigs = (NSArray<KATabConfig*>*)[NSClassFromString(@"LarkKATabRegistry") performSelector: NSSelectorFromString(@"registeredTabConfigs")];
    NSMutableArray* mutableArray = [[NSMutableArray alloc] initWithArray:allConfigs];
    // 默认加上FileTab,为了展示文件相关功能
    [mutableArray insertObject:[FileTabViewController filePreviewerTabConfig] atIndex:[mutableArray count]];
    return mutableArray;
}

+(NSArray<id<FilePreviewer>>*)allFilePreviewers {
    return (NSArray<KATabConfig*>*)[NSClassFromString(@"LarkKAFileRegistry") performSelector: NSSelectorFromString(@"registeredFilePreviewers")];
}

@end
