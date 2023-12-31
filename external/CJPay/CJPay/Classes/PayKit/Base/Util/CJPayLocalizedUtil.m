//
//  CJPayLocalizedUtil.m
//  Pods
//
//  Created by 高航 on 2022/7/27.
//

#import "CJPayLocalizedUtil.h"
#import "CJPayProtocolManager.h"

@implementation CJPayLocalizedUtil

+ (NSString *)localizableStringWithKey:( NSString * )stringKey {
    if(CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin) localizableStringWithKey:stringKey];
    } else {
        NSArray<NSString *> *stringArr = [stringKey componentsSeparatedByString:@"_"];//至少会返回@""
        NSString *str = [stringArr objectAtIndex:0];
        return ((str == nil || str.length == 0) ? @"" : str);
    }
}

+ (void)changeToCustomAppLanguage:(CJPayLocalizationLanguage)language {
    if(CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin) changeToCustomAppLanguage:language];
    }
}

+ (CJPayLocalizationLanguage)getCurrentLanguage {
    if(CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalizedPlugin) getCurrentLanguage];
    } else {
        return CJPayLocalizationLanguageZhhans;
    }
}

@end
