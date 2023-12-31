//
//  CAKLanguageManager.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/10.
//

#import "CAKLanguageManager.h"
#import "CAKResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@interface CAKLanguageManager ()

@property (nonatomic, strong) NSString *currentLanguageCode;

@end


@implementation CAKLanguageManager

+ (instancetype)sharedInstance
{
    static CAKLanguageManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[CAKLanguageManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _currentLanguageCode = @"zh-Hans-CN";
    }
    return self;
}

- (void)setCurrentLanguageCode:(NSString *)currentLanguageCode
{
    _currentLanguageCode = currentLanguageCode;
}

- (NSString *)translatedStringForKey:(NSString *)key defaultTranslation:(NSString *)defaultTranslation
{
    NSString *translatedString = @"";
    NSString *rootPath = [[CAKResourceUnion albumResourceBundle].bundle pathForResource:@"languages" ofType:@""];
    NSString *jsonPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", self.currentLanguageCode]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:jsonPath];
        if (data) {
            NSDictionary *content = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSAssert(content != nil, @"CreativeAlbumKit does not find countryCode:%@", self.currentLanguageCode);
            if (content) {
                translatedString = [content acc_objectForKey:key];
            }
        }
    }
    
    if (!translatedString || [translatedString isEqualToString:@""]) {
        return defaultTranslation;
    }
    return translatedString;
}

@end
