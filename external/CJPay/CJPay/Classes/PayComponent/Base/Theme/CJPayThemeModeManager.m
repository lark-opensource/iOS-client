//
//  CJPayThemeModeManager.m
//  CJComponents
//
//  Created by 易培淮 on 2020/9/25.
//

#import "CJPayThemeModeManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayThemeModeService.h"

@interface CJPayThemeModeManager()<CJPayThemeModeService>

@end

@implementation CJPayThemeModeManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayThemeModeService)
})

+ (instancetype)sharedInstance {
    static CJPayThemeModeManager *themeModeManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        themeModeManager = [CJPayThemeModeManager new];
    });
    return themeModeManager;
}

- (void)i_setThemeModeWithParam:(NSString*)themeMode {
    [self setTheme:themeMode];
}

- (NSString*)i_themeModeStr {
    switch (self.themeMode) {
        case CJPayThemeModeTypeDark:
            return @"dark";
        case CJPayThemeModeTypeLight:
            return @"light";
        case CJPayThemeModeTypeOrigin:
        default:
            return @"";
    }
}

+ (CJPayThemeModeType)themeModeFromString:(NSString *)themeString {
    CJPayThemeModeType result = CJPayThemeModeTypeOrigin;

    NSDictionary *themeMapping = @{
            @"DARK": @(CJPayThemeModeTypeDark),
            @"LIGHT": @(CJPayThemeModeTypeLight),
            @"": @(CJPayThemeModeTypeOrigin),
    };

    NSNumber *value = themeMapping[[themeString uppercaseString]];
    if (value != nil) {
        result = (CJPayThemeModeType)value.unsignedIntValue;
    }
    return result;
}


- (void)setTheme:(NSString*)themeMode {
    self.themeMode = [CJPayThemeModeManager themeModeFromString:themeMode];
}

- (BOOL)isDarkMode {
    if(self.themeMode == CJPayThemeModeTypeDark) {
        return YES;
    }
    return NO;
}

- (BOOL)isLightMode {
    if(self.themeMode == CJPayThemeModeTypeLight) {
        return YES;
    }
    return NO;
}

- (BOOL)isOriginMode {
    return !([self isLightMode] || [self isDarkMode]);
}

@end
