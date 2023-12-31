//
//  LVDLanguageService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import "LVDLanguageService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDLanguageService

- (NSString *)localizedStringWithStr:(NSString * _Nonnull)key defaultTranslation:(NSString * _Nullable)defaultTrans
{
    return [LVDCameraI18N getLocalizedStringWithKey:key defaultStr:defaultTrans];
}

- (NSString * _Nullable)localizedStringWithFormat:(NSString * _Nonnull)key defaultTranslation:(NSString * _Nullable)defaultTrans, ...
{
    va_list ap;
    va_start(ap, defaultTrans);
    NSString *result = [self localizedStringWithFormat:key defaultTranslation:defaultTrans parameters:ap];
    va_end(ap);
    return result;
}

- (NSString * _Nullable)localizedStringWithFormat:(NSString * _Nonnull)key defaultTranslation:(NSString * _Nullable)defaultTrans parameters:(va_list)vaList
{
    NSString *value = defaultTrans;
    if (!value) {
        value = key;
    }
    NSString *ret = [[NSString alloc] initWithFormat:value arguments:vaList];
    return ret;
}
@end
