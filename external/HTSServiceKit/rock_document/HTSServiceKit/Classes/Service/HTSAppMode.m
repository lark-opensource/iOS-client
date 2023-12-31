//
//  HTSAppContext.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSAppMode.h"
#import "HTSMacro.h"

static Class<HTSAppModeProvider> GetCurrentModeProvider(){
    static dispatch_once_t onceToken;
    static Class<HTSAppModeProvider> cls;
    dispatch_once(&onceToken, ^{
        NSString * className = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"HTSAppModeProvider"];
        cls = NSClassFromString(className);
    });
    return cls;
} 

static const char * HTSGetCurrrentBootMode(){
    Class<HTSAppModeProvider> cls = GetCurrentModeProvider();
    if ([cls respondsToSelector:@selector(bootMode)]) {
        const char * bootMode = [cls bootMode];
        return bootMode;
    }
    return HTSAppDefaultMode;
}

FOUNDATION_EXPORT HTSAppModeServicePolicy HTSGetCurrentModeServicePolicy()
{
    Class<HTSAppModeProvider> provider = GetCurrentModeProvider();
    HTSAppModeServicePolicy policy = HTSAppModeServiceDowngradeToDefault;
    if ([provider respondsToSelector:@selector(policyForService)]) {
        policy = [provider policyForService];
    }
    return policy;
}

FOUNDATION_EXPORT BOOL HTSIsDefaultBootMode(){
    static BOOL _res = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _res = (HTSGetCurrrentBootMode() == HTSAppDefaultMode); 
    });
    return _res;
}

FOUNDATION_EXPORT const char * HTSSegmentNameForCurrentMode(){
    static const char * _segment = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char * bootMode = HTSGetCurrrentBootMode();
        if (bootMode == HTSAppDefaultMode) {
            _segment = _HTS_SEGMENT;
        }else{
            _segment = malloc(strlen(bootMode) + strlen("HTS_"));
            strcpy(_segment, "HTS_");
            strcat(_segment,bootMode);
        }
    });
    return _segment;

}
