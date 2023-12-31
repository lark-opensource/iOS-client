//
//  BytedCertLocalization.m
//  BytedCertLocalization
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 Liuchundian. All rights reserved.

#import "BDCTLocalization.h"
#import "BDCTLog.h"
#import "BDCTAdditions.h"


@interface BDCTLocalization ()

@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSDictionary *dict;

@end


@implementation BDCTLocalization

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BDCTLocalization *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BDCTLocalization alloc] init];
        instance.lang = nil;
        instance.dict = nil;
    });
    return instance;
}

#pragma mark - setLanguage

- (void)setLanguage:(NSString *)language {
    self.lang = language;
    [self loadTipDict];
}

- (NSString *)getLanguage {
    if (self.lang == nil) {
        self.lang = [self getPreferredLanguage];
        [self loadTipDict];
    }
    return self.lang;
}

- (NSString *)getPreferredLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *preferredLang = [languages objectAtIndex:0];
    return preferredLang;
}

- (void)loadTipDict {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSBundle *bundle = [NSBundle bdct_bundle];
        if (bundle == nil) {
            BDCTLogInfo(@"byted_cert.bundle not found.\n");
        }

        NSString *res = nil;
        if (bundle) {
            NSString *langFileName;
            if ([self.lang hasPrefix:@"zh"]) {
                langFileName = @"BytedCertLocalizationZh";
            } else if ([self.lang hasPrefix:@"ja"]) {
                langFileName = @"BytedCertLocalizationJa";
            } else {
                langFileName = @"BytedCertLocalizationEn";
            }
            res = [bundle pathForResource:langFileName ofType:@"strings"];
            if (res == nil) {
                BDCTLogInfo(@"byted_cert.bundle resource not found\n");
            }
        }

        if (res) {
            self.dict = [NSDictionary dictionaryWithContentsOfFile:res];
            BDCTLogInfo(@"Load language resource\n");
        }
    });
}

- (NSString *)localString:(NSString *)key {
    // 默认使用系统语言
    if (self.lang == nil) {
        self.lang = [self getPreferredLanguage];
        [self loadTipDict];
    }

    if (self.dict == nil) {
        return key;
    }

    return [self.dict objectForKey:key] ? [self.dict objectForKey:key] : key;
}

@end
