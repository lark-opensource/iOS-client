//
//  ACCUIThemeManager.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import <Foundation/Foundation.h>
#import "ACCUIThemeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCThemeChangeSubscriber <NSObject>

- (void)onThemeChange;

@end

@interface ACCUIThemeManager : NSObject

@property (nonatomic, assign, readonly) ACCUIThemeStyle currentThemeStyle;

+ (instancetype)sharedInstance;

- (void)switchToTheme:(ACCUIThemeStyle)theme;

- (void)addSubscriber:(id<ACCThemeChangeSubscriber>)subscriber;

@end

NS_ASSUME_NONNULL_END
