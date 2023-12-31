//
//  CJPayThemeStyleManager.m
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import "CJPayThemeStyleManager.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayThemeModeManager.h"
#import "CJPayUIMacro.h"
#import "CJPayPrivateServiceHeader.h"

@interface CJPayThemeStyleManager ()<CJPayThemeStyleService>

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong, readwrite) CJPayServerThemeStyle *serverTheme;

@end

@implementation CJPayThemeStyleManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shared), CJPayThemeStyleService)
})

+ (instancetype)shared {
    static CJPayThemeStyleManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayThemeStyleManager alloc] init];
    });
    return manager;
}

- (void)updateStyle:(CJPayServerThemeStyle *)themeStyle {
    if (self.serverTheme != nil) {
        // per-session设置样式，防止在用户使用过程中样式改变
        return;
    }
    // 当themestyle 为空时， 配置默认颜色
    self.serverTheme = themeStyle;
}

- (void)setServerTheme:(CJPayServerThemeStyle *)themeStyle {
    _serverTheme = themeStyle;
    [self p_refreshStyle:_serverTheme];
}

// 必须主线程进行
- (void)p_refreshStyle:(CJPayServerThemeStyle *)themeStyle {
    // 回调到业务层的配置，否则依赖view组件都放进来会增加包大小
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(p_BizRefreshStyle:)] && themeStyle) {
        
        void (^block)(void) = ^{[self performSelector:@selector(p_BizRefreshStyle:) withObject:themeStyle];};
        
        if (NSThread.isMainThread) {
            block();
        } else {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    }
#pragma clang diagnostic pop
    if (themeStyle) {
        [CJPayLocalThemeStyle updateStyleBy:themeStyle];
    }
}

- (void)i_updateThemeStyleWithThemeDic:(NSDictionary *)themeModelDic {
    if (!themeModelDic) {
        return;
    }
    
    NSError *jsonError = nil;
    CJPayServerThemeStyle *serverThemeStyle = [[CJPayServerThemeStyle alloc] initWithDictionary:themeModelDic
                                                                                          error:&jsonError];
    if (serverThemeStyle && !jsonError) {
        [self updateStyle:serverThemeStyle];
    }
}

@end
