//
//  EffectPlatform+Search.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/5/31.
//

#import "EffectPlatform+Search.h"
#import "EffectPlatform+Additions.h"
#import <EffectPlatformSDK/IESEffectLogger.h>

static NSString * const kSearchRecommendPath = @"/effect/api/search/recommend";

static NSString * const kSearchEffectsPath = @"/effect/api/search/effects";

@implementation EffectPlatform (Search)

- (void)fetchSearchRecommendWordsWithPanel:(NSString *)panel
                                  category:(NSString *)category
                           extraParameters:(NSDictionary *)extraParameters
                                completion:(fetchSearchRecommendWordsCompletion)completion {
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionary];
    [totalParameters addEntriesFromDictionary:[self commonParameters]];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"category"] = category ?: @"";
    [totalParameters addEntriesFromDictionary:extraParameters];
    
    NSString *urlString = [self urlWithPath:kSearchRecommendPath];
    [self requestWithURLString:urlString
                    parameters:totalParameters
                        cookie:nil
                    httpMethod:@"GET"
                    completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"fetch search recommend words|panel=%@|category=%@|error=%@", panel, category, error);
        
        if (error) {
            IESEffectLogError(@"fetch search recommend words requested with error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil, nil);
            });
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogError(@"fetch search recommend words requested server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil, nil);
            });
            return;
        }
    
        NSString *searchTips = jsonDict[@"data"][@"search_tips"];
        NSArray *words = jsonDict[@"data"][@"effects"];
        
        NSMutableArray<NSString *> *recommendWords = [NSMutableArray array];
        if (words && [words isKindOfClass:[NSArray class]]) {
            [words enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]] && [obj[@"name"] isKindOfClass:[NSString class]]) {
                    [recommendWords addObject:(NSString *)obj[@"name"]];
                }
            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, searchTips, recommendWords);
        });
    }];
}

- (void)fetchSearchEffectsWithKeyWord:(NSString *)keyword
                             searchID:(NSString *)searchID
                           completion:(fetchSearchEffectsCompletion)completion {
    [self fetchSearchEffectsWithKeyWord:keyword
                               searchID:searchID
                                 cursor:NSNotFound
                              pageCount:NSNotFound
                        extraParameters:@{}
                             completion:completion];
}

- (void)fetchSearchEffectsWithKeyWord:(NSString *)keyword
                             searchID:(NSString *)searchID
                               cursor:(NSInteger)cursor
                            pageCount:(NSInteger)pageCount
                      extraParameters:(NSDictionary *)extraParameters
                           completion:(fetchSearchEffectsCompletion)completion {
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionary];
    [totalParameters addEntriesFromDictionary:[self commonParameters]];
    totalParameters[@"keyword"] = keyword ?: @"";
    totalParameters[@"search_id"] = searchID ?: @"";
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    [totalParameters addEntriesFromDictionary:extraParameters];
    NSString *urlString = [self urlWithPath:kSearchEffectsPath];
    [self requestWithURLString:urlString
                    parameters:totalParameters
                        cookie:nil
                    httpMethod:@"GET"
                    completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"fetch search effects keyword=%@|error=%@", keyword, error);
        
        if (error) {
            IESEffectLogError(@"fetch search effects requested with error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogError(@"fetch search effects requested server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        IESSearchEffectsModel *searchEffectsModel = [MTLJSONAdapter modelOfClass:[IESSearchEffectsModel class]
                                                              fromJSONDictionary:jsonDict[@"data"]
                                                                           error:&mappingError];
        if (mappingError) {
            IESEffectLogError(@"fetch search effects transformed json error:%@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        
        [searchEffectsModel updateEffects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, searchEffectsModel);
        });
    }];
}

@end
