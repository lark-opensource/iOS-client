//
//  BDPAppPagePrefetcherMatchHelper.h
//  TTMicroApp
//
//  Created by 刘焱龙 on 2023/1/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPAppPagePrefetchMatchKey;

@interface BDPAppPagePrefetcherMatchHelper : NSObject

/// URL Match
+ (NSString *)matchURLWithQuery:(NSDictionary *)startPageQueryDictionary
                        storage:(NSDictionary *)storageDic
                     enviroment:(NSDictionary *)enviromentDic
         dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                 inTargetString:(NSString *)targetJSONString
              allContentMatched:(BOOL * _Nonnull)isAllMatched
                       matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                       missKeys:(NSMutableArray *)missKeys
                          appId:(NSString *)appId;

/// Data Match
+ (NSString *)matchDataWithQuery:(NSDictionary *)startPageQueryDictionary
                        storage:(NSDictionary *)storageDic
                     enviroment:(NSDictionary *)enviromentDic
         dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                 inTargetString:(NSString *)targetString
              allContentMatched:(BOOL * _Nonnull)isAllMatched
                       matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                        missKeys:(NSMutableArray *)missKeys
                           appId:(NSString *)appId;

/// Header match
+ (NSDictionary *)matchAllContentsWithQuery:(NSDictionary *)startPageQueryDictionary
                                   storage:(NSDictionary *)storageDic
                                enviroment:(NSDictionary *)enviromentDic
                    dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                                  inTarget:(NSDictionary *)targetDic
                         allContentMatched:(BOOL * _Nonnull)isAllMatched
                                  matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                                   missKeys:(NSMutableArray *)missKeys
                                      appId:(NSString *)appId;

/// Check URL is  match complete
+ (void)checkURLString:(NSString *)urlString
isURLWithoutQueryReady:(BOOL *)isURLWithoutQueryReady
          isQueryReady:(BOOL *)isQueryReady;

@end

NS_ASSUME_NONNULL_END
