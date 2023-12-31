//
//  IESEffectListManager.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/13.
//

#import "IESEffectListManager.h"
#import <EffectPlatformSDK/IESEffectConfig.h>
#import <EffectplatformSDK/IESEffectPlatformResponseModel.h>
#import <EffectPlatformSDK/IESEffectPlatformNewResponseModel.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/NSData+IESEffectManager.h>
#import <EffectPlatformSDK/NSDictionary+EffectPlatfromUtils.h>

#import <TTNetworkManager/TTNetworkManager.h>

// 检查面板特效列表数据是否有更新
static NSString * const kCheckUpdateEffectListPath = @"/effect/api/checkUpdate";

// 获取面板特效列表数据
static NSString * const kFetchEffectListPath = @"/effect/api/v3/effects";

// 检查面板下分类数据（包括热门分类）是否有更新
static NSString * const kCheckUpdateCategoryListPath = @"/effect/api/panel/check";

// 获取面板下分类数据（包括热门分类）
static NSString * const kFetchCategoryListPath = @"/effect/api/panel/info";

// 检查面板下指定分类是否有更新
static NSString * const kCheckUpdateCategoryEffectListPath = @"/effect/api/category/check";

// 获取面板下指定分类的特效列表数据
static NSString * const kFetchCategoryEffectListPath = @"/effect/api/category/effects";

@interface IESEffectListManager ()

@property (nonatomic, copy, readwrite) NSString *accessKey;

@property (nonatomic, strong, readwrite) IESEffectConfig *config;

@end

@implementation IESEffectListManager

- (instancetype)initWithAccessKey:(NSString *)accessKey config:(IESEffectConfig *)config {
    if (self = [super init]) {
        NSParameterAssert(accessKey.length > 0);
        NSParameterAssert(config != nil);
        if (!accessKey || !config) {
            return nil;
        }
        _accessKey = [accessKey copy];
        _config = config;
    }
    return self;
}

#pragma mark - Public

- (void)loadEffectsListWithPanelName:(NSString *)panelName
                          completion:(IESEffectListCompletionBlock)completion {
    if (!panelName) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40051 description:@"Invalid parameter error: panelName is nil."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    NSString *domain = self.config.domain;
    if (!domain) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40052 description:@"Invalid domain error: domain not set."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *fetchPath = kFetchEffectListPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = [self p_cacheKeyForPath:fetchPath panelName:panelName categoryKey:nil];
        NSString *tmpDirectory = self.config.tmpDirectory;
        NSString *cachePath = [tmpDirectory stringByAppendingPathComponent:cacheKey];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
            NSDictionary *cacheDictionary = [NSDictionary dictionaryWithContentsOfFile:cachePath];
            if (cacheDictionary) {
                NSError *parseError = nil;
                IESEffectPlatformResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformResponseModel class]
                                                                          fromJSONDictionary:cacheDictionary
                                                                                       error:&parseError];
                if (responseModel && responseModel.version) {
                    [responseModel setPanelName:panelName];
                    [responseModel preProcessEffects];
                    const NSString *checkUpdateURL = [domain stringByAppendingString:kCheckUpdateEffectListPath];
                    [self p_checkUpdateWithURL:checkUpdateURL
                                     panelName:panelName
                                      category:nil
                                       version:responseModel.version
                                    completion:^(BOOL updated) {
                        if (updated) {
                            NSString *fetchURL = [domain stringByAppendingString:fetchPath];
                            [self p_fetchEffectListWithURL:fetchURL
                                               parametersF:@{@"panel": panelName}
                                                 panelName:panelName
                                                 cachePath:cachePath
                                             responseClass:[IESEffectPlatformResponseModel class]
                                                completion:completion];
                        } else {
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(YES, responseModel, nil, YES);
                                });
                            }
                        }
                    }];
                    
                    return;
                }
            }
        }
        
        NSString *fetchURL = [domain stringByAppendingString:fetchPath];
        [self p_fetchEffectListWithURL:fetchURL
                           parametersF:@{@"panel": panelName}
                             panelName:panelName
                             cachePath:cachePath
                         responseClass:[IESEffectPlatformResponseModel class]
                            completion:completion];
    });
}

- (void)loadCategoryListWithPanelName:(NSString *)panelName
                           completion:(IESEffectListCompletionBlock)completion {
    if (!panelName) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40053 description:@"Invalid parameter error: panelName is nil."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    NSString *domain = self.config.domain;
    if (!domain) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40054 description:@"Invalid domain error: domain not set."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *fetchPath = kFetchCategoryListPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = [self p_cacheKeyForPath:fetchPath panelName:panelName categoryKey:nil];
        NSString *cachePath = [self.config.tmpDirectory stringByAppendingPathComponent:cacheKey];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
            NSDictionary *cacheDictionary = [NSDictionary dictionaryWithContentsOfFile:cachePath];
            if (cacheDictionary) {
                NSError *parseError = nil;
                IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                             fromJSONDictionary:cacheDictionary
                                                                                          error:&parseError];
                if (responseModel && responseModel.version) {
                    [responseModel setPanelName:panelName];
                    [responseModel preProcessEffects];
                    const NSString *checkUpdateURL = [domain stringByAppendingString:kCheckUpdateCategoryListPath];
                    [self p_checkUpdateWithURL:checkUpdateURL
                                     panelName:panelName
                                      category:nil
                                       version:responseModel.version
                                    completion:^(BOOL updated) {
                        if (updated) {
                            NSString *fetchURL = [domain stringByAppendingString:fetchPath];
                            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
                            parameters[@"panel"] = panelName;
                            parameters[@"has_category_effects"] = @(YES);
                            parameters[@"category"] = @"";
                            parameters[@"count"] = @(0);
                            parameters[@"cursor"] = @(0);
                            [self p_fetchEffectListWithURL:fetchURL
                                               parametersF:parameters
                                                 panelName:panelName
                                                 cachePath:cachePath
                                             responseClass:[IESEffectPlatformNewResponseModel class]
                                                completion:completion];
                        } else {
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(YES, responseModel, nil, YES);
                                });
                            }
                        }
                    }];
                    
                    return;
                }
            }
        }
        
        NSString *fetchURL = [domain stringByAppendingString:fetchPath];
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        parameters[@"panel"] = panelName;
        parameters[@"has_category_effects"] = @(YES);
        parameters[@"category"] = @"";
        parameters[@"count"] = @(0);
        parameters[@"cursor"] = @(0);
        [self p_fetchEffectListWithURL:fetchURL
                           parametersF:parameters
                             panelName:panelName
                             cachePath:cachePath
                         responseClass:[IESEffectPlatformNewResponseModel class]
                            completion:completion];
    });
}

- (void)loadCategoryEffectListWithPanelName:(NSString *)panelName
                                categoryKey:(NSString *)categoryKey
                                 completion:(IESEffectListCompletionBlock)completion {
    if (!panelName || !categoryKey) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40055 description:@"Invalid parameter error: panelName or categoryKey is nil."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    NSString *domain = self.config.domain;
    if (!domain) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40056 description:@"Invalid domain error: domain not set."];
            completion(NO, nil, error, NO);
        }
        return;
    }
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *fetchPath = kFetchCategoryEffectListPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = [self p_cacheKeyForPath:fetchPath panelName:panelName categoryKey:categoryKey];
        NSString *cachePath = [self.config.tmpDirectory stringByAppendingPathComponent:cacheKey];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDirectory]) {
            NSDictionary *cacheDictionary = [NSDictionary dictionaryWithContentsOfFile:cachePath];
            if (cacheDictionary) {
                NSError *parseError = nil;
                IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                             fromJSONDictionary:cacheDictionary
                                                                                          error:&parseError];
                if (responseModel && responseModel.version) {
                    [responseModel setPanelName:panelName];
                    [responseModel preProcessEffects];
                    const NSString *checkUpdateURL = [domain stringByAppendingString:kCheckUpdateCategoryEffectListPath];
                    [self p_checkUpdateWithURL:checkUpdateURL
                                     panelName:panelName
                                      category:categoryKey
                                       version:responseModel.version
                                    completion:^(BOOL updated) {
                        if (updated) {
                            NSString *fetchURL = [domain stringByAppendingString:fetchPath];
                            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
                            parameters[@"panel"] = panelName;
                            parameters[@"category"] = categoryKey;
                            parameters[@"count"] = @(0);
                            parameters[@"cursor"] = @(0);
                            parameters[@"sorting_position"] = @(0);
                            [self p_fetchEffectListWithURL:fetchURL
                                               parametersF:parameters
                                                 panelName:panelName
                                                 cachePath:cachePath
                             responseClass:[IESEffectPlatformNewResponseModel class]
                                                completion:completion];
                        } else {
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(YES, responseModel, nil, YES);
                                });
                            }
                        }
                    }];
                    
                    return;
                }
            }
        }
        
        NSString *fetchURL = [domain stringByAppendingString:fetchPath];
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        parameters[@"panel"] = panelName;
        parameters[@"category"] = categoryKey;
        parameters[@"count"] = @(0);
        parameters[@"cursor"] = @(0);
        parameters[@"sorting_position"] = @(0);
        [self p_fetchEffectListWithURL:fetchURL
                           parametersF:parameters
                             panelName:panelName
                             cachePath:cachePath
                         responseClass:[IESEffectPlatformNewResponseModel class]
                            completion:completion];
    });
}

#pragma mark - Private

/**
 * Generate cache key
 * @param path
 * @param panelNamee
 * @param categoryKeye
 */
- (NSString *)p_cacheKeyForPath:(NSString *)path panelName:(NSString *)panelName categoryKey:(NSString *)categoryKey {
    NSString *sdkVersion = self.config.effectSDKVersion;
    NSString *channel = self.config.channel;
    NSString *region = self.config.region;
    NSMutableString *string = [[NSMutableString alloc] initWithString:path];
    [string appendFormat:@"sdk_version=%@", sdkVersion];
    [string appendFormat:@"channel=%@", channel];
    [string appendFormat:@"region=%@", region];
    [string appendFormat:@"panel=%@", panelName];
    if (categoryKey) {
        [string appendFormat:@"category=%@", categoryKey];
    }
    return [[string dataUsingEncoding:NSUTF8StringEncoding] ieseffect_md5String];
}

/**
 * Wrap http request and add common parameters.
 */
- (void)p_sendRequestWithURL:(NSString *)URL
                  parameters:(NSDictionary *)parameters
                  completion:(void (^ __nullable)(NSError * _Nullable error, id _Nullable jsonObj))completion {
    NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
    [totalParameters addEntriesFromDictionary:self.config.commonParameters];
    [totalParameters addEntriesFromDictionary:parameters];
    totalParameters[@"access_key"] = self.accessKey;
    
    // Hook to modify parameters.
    if ([self.delegate respondsToSelector:@selector(effectListManager:willSendRequestWithURL:parameters:)]) {
        [self.delegate effectListManager:self willSendRequestWithURL:URL parameters:totalParameters];
    }
    
    [[TTNetworkManager shareInstance] requestForJSONWithURL:URL
                                                     params:totalParameters
                                                     method:@"GET"
                                           needCommonParams:NO
                                                   callback:^(NSError *error, id jsonObj) {
        if (completion) {
            completion(error, jsonObj);
        }
    }
                                       callbackInMainThread:NO];
}

/**
 * @breif 检查面板下的特效列表是否有更新
 * @param URL 检查特效列表更新的URL
 * @param panelName 面板
 * @param category 分类，使用 categoryKey 字段
 * @param version 缓存的特效列表的版本
 * @param completion Callback block
 */
- (void)p_checkUpdateWithURL:(NSString * _Nonnull)URL
                   panelName:(NSString * _Nonnull)panelName
                    category:(NSString * _Nullable)category
                     version:(NSString * _Nonnull)version
                  completion:(void (^__nullable)(BOOL updated))completion {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    parameters[@"panel"] = panelName;
    parameters[@"version"] = version;
    if (category) {
        parameters[@"category"] = category;
    }
    [self p_sendRequestWithURL:URL parameters:parameters completion:^(NSError * _Nullable error, id  _Nullable jsonObj) {
        if ([jsonObj isKindOfClass:[NSDictionary class]] && !error) {
            BOOL updated = [((NSDictionary *)jsonObj)[@"updated"] boolValue];
            if (completion) {
                completion(updated);
            }
        } else {
            if (completion) {
                completion(YES);
            }
        }
    }];
}

- (void)p_fetchEffectListWithURL:(NSString *)URL
                     parametersF:(NSDictionary *)parameters
                       panelName:(NSString *)panelName
                       cachePath:(NSString *)cachePath
                       responseClass:(Class)responseClass
                      completion:(IESEffectListCompletionBlock)completion {
    [self p_sendRequestWithURL:URL parameters:parameters completion:^(NSError * _Nullable error, id  _Nullable jsonObj) {
        // Network Error
        if (![jsonObj isKindOfClass:[NSDictionary class]] || error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil, error, NO);
                });
            }
            return;
        }
        
        // Server Error
        NSError *serverError = [self.class _serverErrorFromJSON:(NSDictionary *)jsonObj];
        if (serverError) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil, serverError, NO);
                });
            }
            return;
        }
        
        // JSON Parse Error.
        NSDictionary *data = ((NSDictionary *)jsonObj)[@"data"];
        NSError *parseError = nil;
        id responseModel = [MTLJSONAdapter modelOfClass:[responseClass class]
                                     fromJSONDictionary:data
                                                  error:&parseError];
        if (!responseModel || parseError) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil, parseError, NO);
                });
            }
            return;
        }
        
        // Post Parse
        if ([responseModel isKindOfClass:[IESEffectPlatformResponseModel class]]) {
            [(IESEffectPlatformResponseModel *)responseModel setPanelName:panelName];
            [(IESEffectPlatformResponseModel *)responseModel preProcessEffects];
        } else if ([responseModel isKindOfClass:[IESEffectPlatformNewResponseModel class]]) {
            [(IESEffectPlatformNewResponseModel *)responseModel setPanelName:panelName];
            [(IESEffectPlatformNewResponseModel *)responseModel preProcessEffects];
        }
        
        // Save Cache
        if (cachePath.length > 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Remove the NSNull object in data, otherwise writeToFile will fail.
                NSDictionary *dataCopy = [data dictionaryByRemoveNULL];
                [dataCopy writeToFile:cachePath atomically:YES];
            });
        }
        
        // Success
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(YES, responseModel, nil, NO);
            }
        });
    }];
}

#pragma mark - Helpful

+ (NSDictionary *)_errorDescriptionMappingDic {
    static NSDictionary *errorDescriptionMappingDic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errorDescriptionMappingDic = @{
            @(IESEffectErrorUnknowError) : @"unkown error",
            @(IESEffectErrorNotLoggedIn) : @"user not login",
            @(IESEffectErrorParametorError) : @"Illegal parameter (missing or wrong parameter)",
            @(IESEffectErrorIllegalAccessKey) : @"access_key illegal",
            @(IESEffectErrorIllegalAppVersion) : @"app_version illegal",
            @(IESEffectErrorIllegalSDKVersion) : @"sdk_version illegal",
            @(IESEffectErrorIllegalDeviceId) : @"device_id illegal",
            @(IESEffectErrorIllegalDevicePlatform) : @"device_platform illegal",
            @(IESEffectErrorIllegalDeviceType) : @"device_type illegal",
            @(IESEffectErrorIllegalChannel) : @"channel illegal",
            @(IESEffectErrorIllegalAppChannel) : @"app_channel illegal",
            @(IESEffectErrorIllegalPanel) : @"panel illegal",
            @(IESEffectErrorCurrentAppIsNotTestApp) : @"The current application is not a test application",
            @(IESEffectErrorIllegalApp) : @"The current application is not a test application",
            @(IESEffectErrorAccessKeyNotExists) : @"access_key not exist",
        };
    });
    return errorDescriptionMappingDic;
}

+ (NSError *)_serverErrorFromJSON:(NSDictionary *)dictionaryValue {
    NSNumber *statusCode = dictionaryValue[@"status_code"];
    if ([statusCode intValue] == 0) {
        return nil;
    }
    NSString *errorDiscription = [self _errorDescriptionMappingDic][statusCode];
    if (errorDiscription.length == 0) {
        errorDiscription = dictionaryValue[@"message"];
    }
    NSError *serverError = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                               code:[statusCode integerValue]
                                           userInfo:@{NSLocalizedDescriptionKey: errorDiscription ?: @""}];
    return serverError;
}

@end
