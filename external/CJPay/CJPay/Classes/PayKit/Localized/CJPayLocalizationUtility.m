//
//  CJPayLocalizationUtility.m
//  CJPay
//
//  Created by 杨维 on 2018/10/15.
//

#import "CJPayLocalizationUtility.h"
#import "NSBundle+CJPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"

static NSString * const localizationFileName = @"CJPayLocalization";
static NSString * const kCJPayLocalizationLanguageKey = @"kCJPayLocalizationLanguageKey";
static NSString * const kCJPayLanguageKeyZhhans = @"zh-hans";
static NSString * const kCJPayLanguageKeyEn = @"en";

@interface CJPayLocalizationUtility ()<CJPayLocalizedPlugin>

@property (nonatomic, assign) CJPayLocalizationLanguage currentLanguage;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *languageMapInfo;
@property (nonatomic, copy) NSDictionary *base64MapInfo;
@end

@implementation CJPayLocalizationUtility

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedManager), CJPayLocalizedPlugin);
    
});

+ (instancetype)sharedManager {
    static CJPayLocalizationUtility *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.languageMapInfo = @{kCJPayLanguageKeyZhhans : @(CJPayLocalizationLanguageZhhans),
                             kCJPayLanguageKeyEn : @(CJPayLocalizationLanguageEn)
                             };
    self.base64MapInfo = @{@"5pSv5LuY5a6d" : @"QWxpcGF5",//支付宝
                           @"5bCa5pyq5a6J6KOF5b6u5L+h77yM6K+36YCJ5oup5YW25LuW5pSv5LuY5pa55byP" : @"V2VDaGF0IG5vdCBpbnN0YWxsZWQgeWV0LiBQbGVhc2Ugc2VsZWN0IG90aGVyIHBheW1lbnQgbWV0aG9kcw==",//尚未安装微信，请选择其他支付方式
                           @"5bCa5pyq5a6J6KOF5pSv5LuY5a6d77yM6K+36YCJ5oup5YW25LuW5pSv5LuY5pa55byP" : @"QWxpcGF5IG5vdCBpbnN0YWxsZWQgeWV0LiBQbGVhc2Ugc2VsZWN0IG90aGVyIHBheW1lbnQgbWV0aG9kcw=="//尚未安装支付宝，请选择其他支付方式
    };
    
    NSString *fileKey = [[NSUserDefaults standardUserDefaults] valueForKey:kCJPayLocalizationLanguageKey];
    if ([fileKey isKindOfClass:[NSString class]] && fileKey.length > 0) {
        self.currentLanguage = self.languageMapInfo[fileKey].integerValue;
    } else {
        self.currentLanguage = CJPayLocalizationLanguageSystem;
    }
}

#pragma mark - public

- (NSString *)localizableStringWithKey:(NSString *)stringKey {
    NSArray *allKeys = [self.languageMapInfo allKeysForObject:@(self.currentLanguage)];
    NSString *systemLanguage = [NSLocale preferredLanguages].firstObject.lowercaseString;
    NSString *fileKey = nil;
    if (allKeys.count == 1 ) {
        fileKey = allKeys.firstObject;
    } else if ([systemLanguage hasPrefix:kCJPayLanguageKeyEn]) {
        fileKey = kCJPayLanguageKeyEn;
    } else if ([systemLanguage hasPrefix:kCJPayLanguageKeyZhhans]) {
        fileKey = kCJPayLanguageKeyZhhans;
    }
    if ([fileKey isKindOfClass:[NSString class]] && fileKey.length > 0) {
        NSBundle *langBundle = [NSBundle cj_customPayBundle];
        if (!langBundle) {
            return fileKey ?: @"";
        }
        NSString *path = [langBundle pathForResource:fileKey ofType:@"lproj"];
        if (!path || path.length < 1) {
            return fileKey;
        }
        
        NSString *base64Str = [stringKey btd_base64EncodedString];
        if ([self.base64MapInfo cj_stringValueForKey:base64Str] && [fileKey isEqualToString:kCJPayLanguageKeyEn]) {//英文情况下才需要映射
            return [[self.base64MapInfo cj_stringValueForKey:base64Str] btd_base64DecodedString];
        }
        
        return [[NSBundle bundleWithPath:path] localizedStringForKey:stringKey value:nil table:localizationFileName];
    }
    return stringKey;
}

- (void)changeToCustomAppLanguage:(CJPayLocalizationLanguage)language {
    if (self.currentLanguage == language) {
        return;
    }
    self.currentLanguage = language;
    NSArray *allKeys = [self.languageMapInfo allKeysForObject:@(language)];
    BOOL changeSuccess = NO;
    if (allKeys.count == 1) {
        NSString *fileKey = allKeys.firstObject;
        if ([fileKey isKindOfClass:[NSString class]] && fileKey.length > 0) {
            [[NSUserDefaults standardUserDefaults] setValue:fileKey forKey:kCJPayLocalizationLanguageKey];
            changeSuccess = YES;
        }
    }
    if (!changeSuccess) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCJPayLocalizationLanguageKey];
    }
}

- (CJPayLocalizationLanguage)getCurrentLanguage{
    return self.currentLanguage;
}

@end
