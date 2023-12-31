//
//  BDABTestExperimentUpdater.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestExperimentUpdater.h"
#import "BDABTestExperimentItemModel.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>

NSString * const kFetchABResultErrorDomain = @"kFetchABResultErrorDomain";
typedef NS_ENUM(NSUInteger, kFetchABResultErrorCode) {
    kFetchABResultErrorCodeTypeError = 2001,
    kFetchABResultErrorCodeCodeError = 2002,
};

@implementation BDABTestExperimentUpdater

//网络请求
- (void)fetchABTestExperimentsWithURL:(NSString *)url completionBlock:(BDABTestCompletionBlock)completionBlock
{
    [[TTNetworkManager shareInstance] requestForJSONWithURL:url
                                                     params:nil
                                                     method:@"GET"
                                           needCommonParams:YES
                                          requestSerializer:[TTHTTPRequestSerializerBase class]
                                         responseSerializer:[TTHTTPJSONResponseSerializerBase class]
                                                 autoResume:YES
                                                   callback:^(NSError *error, id jsonObj) {
                                                       
                                                       if (error) {
                                                           completionBlock ? completionBlock(nil, nil, error) : nil;
                                                           return;
                                                       }
                                                       
                                                       NSError *jsonError = nil;
                                                       if (![jsonObj isKindOfClass:[NSDictionary class]]) {
                                                           jsonError = [NSError errorWithDomain:kFetchABResultErrorDomain
                                                                                           code:kFetchABResultErrorCodeTypeError
                                                                                       userInfo:@{@"description" : [NSString stringWithFormat:@"%@ isn't NSDictionary", jsonObj]}];
                                                           completionBlock ? completionBlock(nil, nil, jsonError) : nil;
                                                           return;
                                                       }
                                                       
                                                       if (![jsonObj[@"code"] respondsToSelector:@selector(integerValue)] || [jsonObj[@"code"] integerValue] != 0) {
                                                           jsonError = [NSError errorWithDomain:kFetchABResultErrorDomain
                                                                                           code:kFetchABResultErrorCodeCodeError
                                                                                       userInfo:@{@"description" : @"return code isn't 0"}];
                                                           completionBlock ? completionBlock(nil, nil, jsonError) : nil;
                                                           return;
                                                       }
                                                       
                                                       NSDictionary<NSString *, BDABTestExperimentItemModel *> *models = [self modelsWithJsonData:jsonObj[@"data"] error:&jsonError];
                                                       completionBlock ? completionBlock(jsonObj[@"data"], models, jsonError) : nil;
    }];
}

- (NSDictionary<NSString *, BDABTestExperimentItemModel *> *)modelsWithJsonData:(NSDictionary *)jsonData error:(NSError *__autoreleasing *)error {
//    jsonData预期的格式
//    {
//        key1 =         {
//            val = 1;
//            vid = 511340;
//        };
//        key2 =         {
//            val = 2;
//            vid = 511342;
//        }
//    };
    
    __block BOOL hasError = NO;
    __block NSError *errorInBlock = nil;//autoreleasing的error在block中可能会导致内存管理问题 https://fabric.io/zhaokaibytedancecom/ios/apps/com.flipagram.flipagram/issues/5c1f5c7ff8b88c2963ed4b36?time=last-seven-days
    NSMutableDictionary *modelDict = [[NSMutableDictionary alloc] init];
    [jsonData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
        if (![key isKindOfClass:[NSString class]]) {
            errorInBlock = [NSError errorWithDomain:kFetchABResultErrorDomain
                                               code:kFetchABResultErrorCodeTypeError
                                           userInfo:@{@"description" : [NSString stringWithFormat:@"key %@ type is not NSString", key]}];
            hasError = YES;
            *stop = YES;
        }
        else if (![obj isKindOfClass:[NSDictionary class]]) {
            errorInBlock = [NSError errorWithDomain:kFetchABResultErrorDomain
                                               code:kFetchABResultErrorCodeTypeError
                                           userInfo:@{@"description" : [NSString stringWithFormat:@"obj %@ type is not NSDictionary", obj]}];
            hasError = YES;
            *stop = YES;
        }
        else {
            NSString *keyString = key;
            NSDictionary *dic = obj;
            id val = [dic objectForKey:@"val"];
            id vidObj = [dic objectForKey:@"vid"];
            if (![vidObj isKindOfClass:[NSNumber class]]) {
                errorInBlock = [NSError errorWithDomain:kFetchABResultErrorDomain
                                                   code:kFetchABResultErrorCodeTypeError
                                               userInfo:@{@"description" : [NSString stringWithFormat:@"vid %@ type is not NSNumber", vidObj]}];
                hasError = YES;
                *stop = YES;
            }
            else {
                NSString *vid = vidObj;
                BDABTestExperimentItemModel *model = [[BDABTestExperimentItemModel alloc] initWithVal:val vid:vid];
                [modelDict setValue:model forKey:keyString];
            }
        }
    }];
    
    if (hasError) {
        if (error) {
            *error = errorInBlock;
        }
        return nil;
    }
    else {
        return [modelDict copy];
    }
}




@end
