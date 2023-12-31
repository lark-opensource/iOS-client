//
//  IESEffectUtil.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/11.
//

#import "IESEffectUtil.h"
#import "IESEffectLogger.h"
#import "IESAlgorithmRecord.h"
#import "IESEffectAlgorithmModel.h"
#import <EffectSDK_iOS/bef_effect_api.h>

/// when app terminate, we can not call EffectSDK  `bef_effect_peek_resources_needed_by_requirements` method, bacause of crash by
/// accessing static variable
static BOOL kdisablePeekResource = NO;

@implementation IESEffectUtil

+ (void)setDisablePeekResource:(BOOL)disablePeekResource {
    kdisablePeekResource = disablePeekResource;
}

+ (BOOL)disablePeekResource {
    return kdisablePeekResource;
}

+ (BOOL)isVersion:(NSString *)version higherOrEqualThan:(NSString *)baseVersion {
    if (version.length > 0 && baseVersion.length > 0) {
        NSArray *versionArray = [version componentsSeparatedByString:@"."];
        NSArray *baseVersionArray = [baseVersion componentsSeparatedByString:@"."];
        if (versionArray.count >= 2 && baseVersionArray.count >= 2) {
            NSInteger versionMajor = [(NSString *)versionArray[0] integerValue];
            NSInteger versionMinor = [(NSString *)versionArray[1] integerValue];
            NSInteger baseVersionMajor = [(NSString *)baseVersionArray[0] integerValue];
            NSInteger baseVersionMinor = [(NSString *)baseVersionArray[1] integerValue];
            if (versionMajor > baseVersionMajor) {
                return YES;
            } else if (versionMajor == baseVersionMajor) {
                return versionMinor >= baseVersionMinor;
            }
        }
    }
    
    return NO;
}

+ (BOOL)isVersion:(NSString *)version higherThan:(NSString *)baseVersion {
    if (version.length > 0 && baseVersion.length > 0) {
        NSArray *versionArray = [version componentsSeparatedByString:@"."];
        NSArray *baseVersionArray = [baseVersion componentsSeparatedByString:@"."];
        if (versionArray.count >= 2 && baseVersionArray.count >= 2) {
            NSInteger versionMajor = [versionArray[0] integerValue];
            NSInteger versionMinor = [(NSString *)versionArray[1] integerValue];
            NSInteger baseVersionMajor = [baseVersionArray[0] integerValue];
            NSInteger baseVersionMinor = [(NSString *)baseVersionArray[1] integerValue];

            if (versionMajor > baseVersionMajor) {
                return YES;
            } else if (versionMajor == baseVersionMajor) {
                return versionMinor > baseVersionMinor;
            }
        }
    }
    
    return NO;
}

+ (BOOL)compareOnlineModel:(IESEffectAlgorithmModel *)onlineModel withBaseRecord:(IESAlgorithmRecord *)record {
    return [self isVersion:onlineModel.version higherThan:record.version] || onlineModel.sizeType != record.sizeType || ![onlineModel.modelMD5 isEqualToString:record.modelMD5];
}

+ (NSSet<NSString *> *)mergeRequirements:(NSArray<NSString *> *)requirements withModelNames:(NSDictionary<NSString *,NSArray<NSString *> *> *)modelNames {
    NSMutableSet<NSString *> *mergeResults = [[NSMutableSet alloc] init];
    
    NSArray<NSString *> *modelNamesOfRequirements = [self getAlgorithmNamesFromAlgorithmRequirements:requirements];
    [mergeResults addObjectsFromArray:modelNamesOfRequirements];
    
    [modelNames enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull algorithmName, NSArray<NSString *> * _Nonnull algorithmModelNames, BOOL * _Nonnull stop) {
        [mergeResults addObjectsFromArray:algorithmModelNames];
    }];
    return [mergeResults copy];
}

+ (NSArray<NSString *> *)getAlgorithmNamesFromAlgorithmRequirements:(NSArray<NSString *> *)algorithmRequirements {
#if TARGET_IPHONE_SIMULATOR
    return @[];
#else
    if (kdisablePeekResource) {
        return @[];
    }
    int requirementsCount = (int)algorithmRequirements.count;
    if (requirementsCount > 0) {
        // Prepare Paramenters
        char **cargs = (char **)malloc(sizeof(char *) * requirementsCount);
        for (NSInteger index = 0; index < requirementsCount; index++) {
            NSString *requirement = algorithmRequirements[index];
            const char *requirementInCStr = [requirement cStringUsingEncoding:NSUTF8StringEncoding];
            cargs[index] = (char *)requirementInCStr;
        }
        
        // Call EffectSDK api
        const char **outAlgorithmNames = NULL;
        int outAlgorithmNamesSize = 0;
        bef_effect_result_t result = bef_effect_peek_resources_needed_by_requirements((const char **)cargs, requirementsCount, &outAlgorithmNames, &outAlgorithmNamesSize);
        if (result != BEF_RESULT_SUC) {
            IESEffectLogError(@"bef_effect_peek_resources_needed_by_requirements error: %d", result);
        }
        free(cargs);
        
        // Out Resource Names
        if (outAlgorithmNames != NULL) {
            NSMutableSet *algorithmNames = [[NSMutableSet alloc] initWithCapacity:outAlgorithmNamesSize];
            for (NSInteger index = 0; index < outAlgorithmNamesSize; index++) {
                const char *algorithmNameInCStr = outAlgorithmNames[index];
                NSString *algorithmName = [NSString stringWithUTF8String:algorithmNameInCStr];
                [algorithmNames addObject:algorithmName];
            }
            free(outAlgorithmNames);
            return [algorithmNames allObjects];
        }
    }
    
    return nil;
#endif
}

// 判断是否符合version的规范
+ (BOOL)isVersionString:(NSString *)string {
    if (!string || (string && string.length == 0)) return NO;
    
    NSString *versionPattern = @"^[0-9.]+";
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", versionPattern];
    return [pre evaluateWithObject:string];
}

+ (BOOL)getShortNameAndVersionWithModelName:(NSString *)modelName shortName:(NSString **)shortName version:(NSString **)version {
    NSRange range = [modelName rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.length > 0) {
        modelName = [modelName substringFromIndex:range.location+range.length];
    }
    if ([modelName hasSuffix:@".model"]) {
        modelName = [modelName substringToIndex:modelName.length - 6];
    } else if ([modelName hasSuffix:@".dat"]) {
        modelName = [modelName substringToIndex:modelName.length - 4];
    }
    
    range = [modelName rangeOfString:@"_v" options:NSBackwardsSearch];
    if (range.length > 0) {
        NSString *shortNameString = [modelName substringToIndex:range.location];
        NSString *versionString = [modelName substringFromIndex:range.location + range.length];
        if ([self isVersionString:versionString]) {
            *shortName = shortNameString;
            *version = versionString;
        } else {
            *shortName = modelName;
            *version = @"0.0";
        }
        return YES;
    } else {
        *shortName = modelName;
        *version = @"0.0";
        return YES;
    }
}

+ (void)parseModelFilePath:(NSString *)modelFilePath completion:(void(^)(BOOL isSuccess, NSString * __nullable shortName, NSString * __nullable version, NSInteger sizeType))completion
{
    NSString *lastPathComponent = modelFilePath.lastPathComponent;
    NSString *pathExtension = [lastPathComponent pathExtension];
    if (![pathExtension isEqualToString:@"model"] && ![pathExtension isEqualToString:@"dat"]) {
        // ⚠️ incorrect model name!
        if (completion) {
            completion(NO, nil, nil, NSNotFound);
        }
        return;
    }
    
    NSString *modelNameDeletingPathExtension = [lastPathComponent stringByDeletingPathExtension];
    NSRange versionBeginRange = [modelNameDeletingPathExtension rangeOfString:@"_v" options:NSBackwardsSearch];
    NSRange sizeTypeBeginRange = [modelNameDeletingPathExtension rangeOfString:@"_size" options:NSBackwardsSearch];
    if (versionBeginRange.length <= 0) {
        // ⚠️ incorrect model name!
        if (completion) {
            completion(NO, nil, nil, NSNotFound);
        }
        return;
    }
    NSString *shortNameString = [modelNameDeletingPathExtension substringToIndex:versionBeginRange.location];
    NSString *versionString = nil;
    NSString *sizeTypeString = nil;
    
    if (sizeTypeBeginRange.length > 0 &&
        sizeTypeBeginRange.location > versionBeginRange.location + versionBeginRange.length) {
        // has '_sizeXXX'
        NSRange versionStringRange = NSMakeRange(versionBeginRange.location + versionBeginRange.length, sizeTypeBeginRange.location - versionBeginRange.location - versionBeginRange.length);
        versionString = [modelNameDeletingPathExtension substringWithRange:versionStringRange];
        sizeTypeString = [modelNameDeletingPathExtension substringFromIndex:sizeTypeBeginRange.location + sizeTypeBeginRange.length];
    } else {
        // '_sizeXXX' not found
        NSRange versionStringRange = NSMakeRange(versionBeginRange.location + versionBeginRange.length, modelNameDeletingPathExtension.length - versionBeginRange.location - versionBeginRange.length);
        versionString = [modelNameDeletingPathExtension substringWithRange:versionStringRange];
    }
        
    if (completion) {
        completion(YES, shortNameString, versionString, sizeTypeString.integerValue);
    }
}

@end
