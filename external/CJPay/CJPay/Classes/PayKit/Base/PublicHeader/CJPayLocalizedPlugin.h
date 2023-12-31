//
//  CJPayLocalizedPlugin.h
//  Pods
//
//  Created by 高航 on 2022/7/27.
//

#ifndef CJPayLocalizedPlugin_h
#define CJPayLocalizedPlugin_h

typedef NS_ENUM(NSUInteger, CJPayLocalizationLanguage) {
    CJPayLocalizationLanguageSystem = 0,            //默认跟随系统
    CJPayLocalizationLanguageZhhans,     //简体中文
    CJPayLocalizationLanguageEn,               //英文
};
NS_ASSUME_NONNULL_BEGIN

@protocol CJPayLocalizedPlugin <NSObject>

- (NSString *)localizableStringWithKey:(NSString *)stringKey;
- (void)changeToCustomAppLanguage:(CJPayLocalizationLanguage)language;
- (CJPayLocalizationLanguage)getCurrentLanguage;

@end

NS_ASSUME_NONNULL_END
#endif /* CJPayLocalizedPlugin_h */
