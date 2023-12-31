//
//  ACCUIThemeManager.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import "ACCUIThemeManager.h"
#import "ACCServiceLocator.h"
#import "ACCMacros.h"
#import "UIViewController+ACCUITheme.h"

#import <IESInject/IESInject.h>

@interface ACCUIThemeManager ()

@property (nonatomic, assign, readwrite) ACCUIThemeStyle currentThemeStyle;
@property (nonatomic, strong) NSHashTable<id<ACCThemeChangeSubscriber>> *subscribers;

@end

@implementation ACCUIThemeManager

+ (instancetype)sharedInstance
{
    static ACCUIThemeManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ACCUIThemeManager alloc] init];
        manager.currentThemeStyle = [IESAutoInline(ACCBaseServiceProvider(), ACCUIThemeProtocol) initialThemeStyle] ?: ACCUIThemeStyleDark;
        manager.subscribers = [[NSHashTable alloc] init];
    });
    return manager;
}

- (void)switchToTheme:(ACCUIThemeStyle)theme
{
    if (self.currentThemeStyle == theme) {
        return;
    }
    
    self.currentThemeStyle = theme;
    for (id <ACCThemeChangeSubscriber> subscriber in self.subscribers.allObjects) {
        [subscriber onThemeChange];
    }
    
    // dynamic reload from root window
    [[UIApplication sharedApplication].windows enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.rootViewController acc_themeReload];
    }];
}

- (void)addSubscriber:(id<ACCThemeChangeSubscriber>)subscriber
{
    [self.subscribers addObject:subscriber];
}

@end
