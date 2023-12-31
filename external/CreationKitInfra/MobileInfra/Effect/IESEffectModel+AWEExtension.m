//
//  IESEffectModel+AWEExtension.m
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "IESEffectModel+AWEExtension.h"
#import <objc/message.h>
#import "ACCI18NConfigProtocol.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import "ACCLogProtocol.h"
#import "NSDictionary+ACCAddition.h"

#ifndef ALPSwizzle

#define ALPSwizzle(class, oriMethod, newMethod) {Method originalMethod = class_getInstanceMethod(class, @selector(oriMethod));\
Method swizzledMethod = class_getInstanceMethod(class, @selector(newMethod));\
if (class_addMethod(class, @selector(oriMethod), method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {\
    class_replaceMethod(class, @selector(newMethod), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));\
} else {\
    method_exchangeImplementations(originalMethod, swizzledMethod);\
}}

#endif

NSString *const AWEColorFilterBiltinResourceName = @"acc.color.filter.buitin.resouce.name";

@implementation IESEffectModel (AWEExtension)

AWELazyRegisterPremainClassCategory(IESEffectModel, AWEExtension)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ALPSwizzle(self, effectName, acc_effectName);
    });
}

- (NSString *)acc_effectName
{
    if (self.builtinResource) {
        NSString *language = [ACCI18NConfig() currentLanguage];
        if (![language isEqualToString:@"zh"] && [self effectNameEn]) {
            return [self effectNameEn];
        }
    }
    
    return self.acc_effectName;
}

- (NSString *)effectNameEn
{
    return objc_getAssociatedObject(self, @selector(effectNameEn));
}

- (void)setEffectNameEn:(NSString *)value
{
    objc_setAssociatedObject(self, @selector(effectNameEn), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)builtinIcon
{
    return objc_getAssociatedObject(self, @selector(builtinIcon));
}

- (void)setBuiltinIcon:(NSString *)value
{
    objc_setAssociatedObject(self, @selector(builtinIcon), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)builtinResource
{
    return objc_getAssociatedObject(self, @selector(builtinResource));
}

- (void)setBuiltinResource:(NSString *)value
{
    objc_setAssociatedObject(self, @selector(builtinResource), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)acc_iconImage
{
    return objc_getAssociatedObject(self, @selector(acc_iconImage));
}

- (void)setAcc_iconImage:(UIImage *)value
{
//    objc_setAssociatedObject(self, @selector(acc_iconImage), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)resourcePath
{
    NSString *path = nil;
    
    if (self.builtinResource) {
        path = self.builtinResource;
    } else {
        path = self.filePath;
    }
    
    if (path == nil) {
        path = @"";
    }
    
    return path;
}

- (NSString *)pinyinName
{
   __block NSString *pinyin = nil;
    
    [self.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@"pinyin:"]) {
            pinyin = [obj componentsSeparatedByString:@":"].lastObject;
        }
    }];
    
    return pinyin ?: self.effectName;
}

- (BOOL)isNormalFilter
{
    return [self.tags containsObject:@"normal"];
}

- (BOOL)needServerExcute
{
    return [self.tags containsObject:@"NeedServerAlgorithm"];
}

- (BOOL)acc_needLocalAlgorithmExcute
{
    return [self.tags containsObject:@"NeedLocalAlgorithm"];
}

- (NSString *)filePathForCameraPosition:(AVCaptureDevicePosition)position
{
    NSString *configFilePath = [self.resourcePath stringByAppendingPathComponent:@"config.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:configFilePath]) { // No config file = > is a normal filter
        return self.resourcePath;
    }

    NSData *configData = [NSData dataWithContentsOfFile:configFilePath];
    if (!configData) { // Config file content is empty = > is a normal filter
        return self.resourcePath;
    }

    NSError *jsonSerializationError = nil;
    NSDictionary *configContent = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&jsonSerializationError];

    if (!configContent || jsonSerializationError) { // Config file parsing JSON content error = > is a common filter
        return self.resourcePath;
    }

    if (![configContent acc_stringValueForKey:@"front_dir"] ||
        ![configContent acc_stringValueForKey:@"back_dir"] ||
        ACC_isEmptyString([configContent acc_stringValueForKey:@"front_dir"]) ||
        ACC_isEmptyString([configContent acc_stringValueForKey:@"back_dir"])) { // The config file resolves that there is no front in JSON_ dir、back_ The dir field or field value is empty = > is a normal filter
        return self.resourcePath;
    }

    NSString *backResourcesDir = [self.resourcePath stringByAppendingPathComponent:[configContent acc_stringValueForKey:@"back_dir"]];
    NSString *frontResourcesDir = [self.resourcePath stringByAppendingPathComponent:[configContent acc_stringValueForKey:@"front_dir"]];

    // front_ dir、back_ The file corresponding to dir does not exist = > is a common filter
    if (position == AVCaptureDevicePositionBack) {
        return [[NSFileManager defaultManager] fileExistsAtPath:backResourcesDir] ? backResourcesDir : self.resourcePath;
    } else {
        return [[NSFileManager defaultManager] fileExistsAtPath:frontResourcesDir] ? frontResourcesDir : self.resourcePath;
    }
}


- (BOOL)isEmptyFilter
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIsEmptyFilter:(BOOL)isEmptyFilter
{
    objc_setAssociatedObject(self, @selector(isEmptyFilter), @(isEmptyFilter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSArray<IESEffectModel *> *)acc_builtinEffects
{
    NSMutableArray *effectArray = @[].mutableCopy;
    NSString *normalResource = [NSString acc_strValueWithName:AWEColorFilterBiltinResourceName];
    NSString *filterBundlePath = [NSString acc_bundlePathWithName:@"Filter"];
    NSArray *effectDic = @[@{@"effectName":ACCLocalizedString(@"filter_local_normal", @"normal"),
                             @"effectIdentifier":@"100",
                             @"sourceIdentifier":@"100",
                             @"resourceId": @"100",
                             @"builtinIcon":[[filterBundlePath stringByAppendingPathComponent:normalResource] stringByAppendingPathComponent:@"thumbnail.jpg"],
                             @"builtinResource":[filterBundlePath stringByAppendingPathComponent:normalResource],
                             @"types":@[@"cfilter"],
                             @"tags":@[@"pinyin:normal",@"normal"],
                             @"effectNameEn":@"Normal",
                             @"isBuildin" : @(YES),
                             @"extra": @"{\"filterconfig\":\"{\\\"items\\\":[{\\\"min\\\":0,\\\"max\\\":100,\\\"value\\\":38,\\\"tag\\\":\\\"Filter_intensity\\\",\\\"name\\\":\\\"Filter_intensity\\\"}]}\"}",
                             },
                           @{@"effectName":ACCLocalizedString(@"filter_local_baixi", @"F1"),
                             @"effectIdentifier":@"102",
                             @"sourceIdentifier":@"102",
                             @"resourceId": @"102",
                             @"builtinIcon":[[filterBundlePath stringByAppendingPathComponent:@"Filter_22"] stringByAppendingPathComponent:@"thumbnail.jpg"],
                             @"builtinResource":[filterBundlePath stringByAppendingPathComponent:@"Filter_22"],
                             @"types":@[@"cfilter"],
                             @"tags":@[@"pinyin:baixi"],
                             @"effectNameEn":@"F1",
                             @"isBuildin" : @(YES),
                             @"extra": @"{\"filterconfig\":\"{\\\"items\\\":[{\\\"min\\\":0,\\\"max\\\":100,\\\"value\\\":100,\\\"tag\\\":\\\"Filter_intensity\\\",\\\"name\\\":\\\"Filter_intensity\\\"}]}\"}",
                             },
                           @{@"effectName":ACCLocalizedString(@"filter_local_rixi", @"F4"),
                             @"effectIdentifier":@"101",
                             @"sourceIdentifier":@"101",
                             @"resourceId": @"101",
                             @"builtinIcon":[[filterBundlePath stringByAppendingPathComponent:@"Filter_25"] stringByAppendingPathComponent:@"thumbnail.jpg"],
                             @"builtinResource":[filterBundlePath stringByAppendingPathComponent:@"Filter_25"],
                             @"types":@[@"cfilter"],
                             @"tags":@[@"pinyin:rixi"],
                             @"effectNameEn":@"F4",
                             @"isBuildin" : @(YES),
                             @"extra": @"{\"filterconfig\":\"{\\\"items\\\":[{\\\"min\\\":0,\\\"max\\\":100,\\\"value\\\":75,\\\"tag\\\":\\\"Filter_intensity\\\",\\\"name\\\":\\\"Filter_intensity\\\"}]}\"}",
                             },
                           ];
    
    for (NSDictionary *dic in effectDic) {
        NSError *error = nil;
        IESEffectModel *effect = [[IESEffectModel alloc] initWithDictionary:dic error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"json convert to IESEffectModel error: %@", error);
        }
        if (effect) {
            [effectArray addObject:effect];
        }
    }
    
    return effectArray;
}

@end
