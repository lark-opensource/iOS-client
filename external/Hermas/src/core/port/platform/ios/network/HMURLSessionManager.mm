//
//  HMURLSessionManager.m
//  Hermas
//
//  Created by 崔晓兵 on 6/1/2022.
//

#import "HMURLSessionManager.h"
#import "HMConfig.h"
#import "log.h"

static id objectForInsensitiveKey(NSDictionary* dic, NSString *key) {
    __block id object = nil;
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull objKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([objKey isKindOfClass:NSString.class]) {
            if ([key caseInsensitiveCompare:objKey] == NSOrderedSame) {
                object = obj;
                *stop = YES;
            }
        }
    }];
    return object;
}

static NSDictionary * respondDictionaryWith(NSData *data, NSURLResponse *response, NSError *error) {
    @autoreleasepool {
        NSMutableDictionary *rs = [NSMutableDictionary dictionary];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse.URL.absoluteString containsString:@"zstd_dict"]) {
                
            }
            NSInteger statusCode = [httpResponse statusCode];
            NSDictionary *headerFields = [httpResponse allHeaderFields];
            [rs setValue:@(statusCode) forKey:@"status_code"];
            //ran is the key for aes
            NSString *ran = objectForInsensitiveKey([httpResponse allHeaderFields], @"ran");
            if (ran && [ran isKindOfClass:NSString.class]) [rs setValue:ran forKey:@"ran"];
            //x-tt-logid is the id for event trace
            NSString *xTTLogid = [headerFields objectForKey:@"x-tt-logid"];
            [rs setValue:xTTLogid forKey:@"x-tt-logid"];
        } else if (response) {
            loge("Hermas", "Hermas HTTP response is not NSHTTPURLResponse");
        }
        if (!error) {
            @try {
                NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [rs setValue:jsonObj forKey:@"result"];
                if (response) {
                    [rs setValue:@YES forKey:@"has_response"];
                }
            } @catch (NSException *exception) {
            } @finally {
            }
        }
        return rs;
    }
}

@implementation HMURLSessionManager

- (void)requestWithModel:(HMRequestModel *)model callback:(JSONFinishBlock)callback {
    NSAssert(![NSThread isMainThread], @"Please do not request network service on the main thread! Otherwise, the network library may report errors!");
    @autoreleasepool {
        NSMutableURLRequest *request = [self requestWithModel:model];
        [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError * error) {
            NSDictionary *rs = respondDictionaryWith(data, response, error);
            if(callback) {
                callback(error, [rs copy]);
            }
        }] resume];
    }
}

- (NSMutableURLRequest *)requestWithModel:(HMRequestModel *)model {
    @autoreleasepool {
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:model.requestURL]];
        [request setHTTPMethod:model.method];
        [request setTimeoutInterval:60];
        [model.headerField enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        if([request.HTTPMethod isEqualToString:@"POST"]) {
            [request setHTTPBody:model.postData];
            if (model.needEcrypt) {
                [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
            }
        }
        
        return request;
    }
}

@end
