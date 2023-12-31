//
//  ACCLanguageProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by wishes on 2019/12/29.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

#define ACC_LANGUAGE_DISABLE_LOCALIZATION(obj)\
do {\
    if ([ACCLanguage() respondsToSelector:@selector(disableLocalizationsOfObj:)]) { \
        [ACCLanguage() disableLocalizationsOfObj:obj]; \
    }\
} while(0);\

#define ACCLocalizedString(str,defaultTrans)  [ACCLanguage() localizedStringWithStr:str defaultTranslation:nil]
#define ACCLocalizedCurrentString(str)  [ACCLanguage() localizedStringWithStr:str defaultTranslation:nil]
#define ACCLocalizedStringWithFormat(format, defaultTrans, ...) [ACCLanguage() localizedStringWithFormat:format defaultTranslation:defaultTrans, __VA_ARGS__]

@protocol ACCLanguageProtocol <NSObject>

- (NSString * _Nullable)localizedStringWithStr:(NSString * _Nonnull)key defaultTranslation:(NSString * _Nullable)defaultTrans;

- (NSString * _Nullable)localizedStringWithFormat:(NSString * _Nonnull)key defaultTranslation:(NSString * _Nullable)defaultTrans, ...;

@optional
- (void)disableLocalizationsOfObj:(NSObject *)obj;

/// plural string with count
- (NSString * _Nullable)pluralizedStringWithString:(NSString * _Nonnull)key count:(NSInteger)count;
/// formate number to string localized
- (NSString *)formatedNumber:(long long)number;

/// locale
- (NSString *)currentLanguageLocale;
- (NSString *)currentLanguageLocalizedDisplayName;

@end

FOUNDATION_STATIC_INLINE id<ACCLanguageProtocol> ACCLanguage() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCLanguageProtocol)];
}
