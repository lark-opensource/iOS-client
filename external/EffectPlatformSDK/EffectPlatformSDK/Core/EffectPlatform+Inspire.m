//
//  EffectPlatform+Inspire.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/10/9.
//

#import "EffectPlatform+Inspire.h"
#import "EffectPlatform+Additions.h"
#import <EffectPlatformSDK/IESEffectLogger.h>

static NSString * const kTopListEffectPath = @"/effect/api/topchecklist/effects";

static NSString * const kInspirationEffectPath = @"/aweme/v1/inspiration/feed/";

@implementation EffectPlatform (Inspire)

- (void)fetchTopListEffectsWithPanel:(NSString *)panel
                     extraParameters:(NSDictionary *)extraParameters
                          completion:(nonnull void (^)(NSError * _Nullable,
                                                       IESEffectTopListResponseModel * _Nullable))completion {
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionary];
    [totalParameters addEntriesFromDictionary:[self commonParameters]];
    totalParameters[@"panel"] = panel ?: @"";
    if (extraParameters) {
        [totalParameters addEntriesFromDictionary:extraParameters];
    }
    NSString *urlString = [self urlWithPath:kTopListEffectPath];
    
    [self requestWithURLString:urlString
                    parameters:totalParameters
                        cookie:nil
                    httpMethod:@"GET"
                    completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"fetch top list effects panel=%@|error=%@", panel, error ?: @"");
        
        if (error) {
            IESEffectLogError(@"fetch top list effects requested with error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogError(@"fetch top list effects requested server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        if (!jsonDict || ![jsonDict[@"data"] isKindOfClass:[NSDictionary class]]) {
            IESEffectLogError(@"fetch top list but json invalid!!!");
            NSError *jsonError = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                                     code:IESEffectErrorUnknowError
                                                 userInfo:@{NSLocalizedDescriptionKey : @"fetch top list json invalid"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(jsonError, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        IESEffectTopListResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectTopListResponseModel class]
                                                                 fromJSONDictionary:jsonDict[@"data"]
                                                                              error:&mappingError];
        [responseModel updateEffects];
        
        if (mappingError) {
            IESEffectLogError(@"transform to IESEffecTopListResponseModel model failed with %@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel);
        });
    }];
}

- (void)fetchRecommendInspiredEffectsWithRequestURL:(NSString *)requestURL
                                           category:(NSInteger)categoryID
                                              count:(NSInteger)count
                                    extraParameters:(NSDictionary *)extraParameters
                                         completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion {
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionary];
    [totalParameters addEntriesFromDictionary:[self commonParameters]];
    totalParameters[@"inspiration_category"] = @(categoryID);
    totalParameters[@"count"] = @(count);
    if (extraParameters) {
        [totalParameters addEntriesFromDictionary:extraParameters];
    }
    NSString *urlString = [NSString stringWithFormat:@"%@%@", requestURL, kInspirationEffectPath];
    
    [self requestWithURLString:urlString
                    parameters:totalParameters
                        cookie:nil
                    httpMethod:@"GET"
                    completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"fetch effects categoryID=%@|count=%@|error=%@", @(categoryID), @(count), error ?: @"");
        
        if (error) {
            IESEffectLogError(@"fetch recommend inspired effects requested with error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogError(@"fetch recommend inspired effects requested server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        NSArray *awemeJsonArray = jsonDict[@"inspiration_awemes"];
        NSMutableArray<IESEffectModel *> *effects = [NSMutableArray array];
        
        if ([awemeJsonArray isKindOfClass:[NSArray class]]) {
            [awemeJsonArray enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]] &&
                    [obj[@"materials"] isKindOfClass:[NSArray class]] &&
                    [[obj[@"materials"] firstObject] isKindOfClass:[NSDictionary class]] &&
                    [obj[@"aweme"] isKindOfClass:[NSDictionary class]]) {
                    NSError *mappingError = nil;
                    NSDictionary *material = [obj[@"materials"] firstObject];
                    IESEffectModel *effect = [MTLJSONAdapter modelOfClass:[IESEffectModel class]
                                                       fromJSONDictionary:material[@"sticker_data"]
                                                                    error:&mappingError];
                    if (mappingError) {
                        IESEffectLogError(@"transform effect model failed with %@ in inspiration recommend", mappingError);
                    }
                    
                    if (effect && material[@"use_count"]) {
                        effect.use_number = [material[@"use_count"] unsignedLongLongValue];
                    }
                    
                    NSDictionary *awemeJsonDict = obj[@"aweme"];
                    if ([awemeJsonDict[@"video"] isKindOfClass:[NSDictionary class]] && awemeJsonDict[@"video"][@"play_addr"]) {
                        NSArray *videoURLs = awemeJsonDict[@"video"][@"play_addr"][@"url_list"];
                        if (effect && [videoURLs isKindOfClass:[NSArray class]]) {
                            effect.videoPlayURLs = videoURLs;
                        }
                    }
                    
                    [self p_parseAuthorInfoFromAwemeJsonDict:awemeJsonDict forEffect:effect];
                    
                    if (effect) {
                        [effects addObject:effect];
                    }
                }
            }];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, effects);
        });
    }];
}


- (void)p_parseAuthorInfoFromAwemeJsonDict:(NSDictionary *)awemeJsonDict
                                 forEffect:(IESEffectModel *)effect {
    if ([awemeJsonDict[@"author"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *authorInfo = awemeJsonDict[@"author"];
        NSString *nickName = authorInfo[@"nickname"];
        if (effect && [nickName isKindOfClass:[NSString class]]) {
            effect.nickName = nickName;
        }
        
        if (authorInfo[@"avatar_thumb"] &&
            [authorInfo[@"avatar_thumb"] isKindOfClass:[NSDictionary class]]) {
            NSString *avatarThumbURI = authorInfo[@"avatar_thumb"][@"uri"];
            NSArray *avatarThumbURLs = authorInfo[@"avatar_thumb"][@"url_list"];
            if (effect && [avatarThumbURI isKindOfClass:[NSString class]]) {
                effect.avatarThumbURI = avatarThumbURI;
            }
            if (effect && [avatarThumbURLs isKindOfClass:[NSArray class]]) {
                effect.avatarThumbURLs = avatarThumbURLs;
            }
        }
    }
}

@end
