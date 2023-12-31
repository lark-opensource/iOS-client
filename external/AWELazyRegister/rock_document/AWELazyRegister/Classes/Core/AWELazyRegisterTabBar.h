//
//  AWELazyRegisterTabBar.h
//  AWELazyRegister-Pods-Aweme
//
//  Created by 陈煜钏 on 2021/4/9.
//

#import <Foundation/Foundation.h>

#import "AWELazyRegister.h"

#define AWELazyRegisterModuleNormalTabBar "NormalTabBar"
#define AWELazyRegisterNormalTabBar()   AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleNormalTabBar)

#define AWELazyRegisterModuleTeenModeTabBar "TeenModeTabBar"
#define AWELazyRegisterTeenModeTabBar() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleTeenModeTabBar)

extern void AWEEvaluateLazyRegisterNormalTabBar();
extern void AWEEvaluateLazyRegisterTeenModeTabBar();

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterTabBar : NSObject

@end

NS_ASSUME_NONNULL_END
