//
//  TTRedirectTask.m
//  TTNetworkManager
//
//  Created by bytedance on 2022/9/5.
//

#import <Foundation/Foundation.h>

#import "TTRedirectTask.h"
#import "TTHttpTask.h"

@interface TTRedirectTask ()

@property (nonatomic, weak) TTHttpTask * _Nullable task;

@property (atomic, copy, readwrite) NSMutableDictionary<NSString *, NSString *> *allHTTPHeaders;

@property (atomic, copy, readwrite) NSMutableArray<NSString *> *removedHeaders;
@property (atomic, copy, readwrite) NSMutableDictionary<NSString *, NSString *> *modifiedHeaders;
@end

@implementation TTRedirectTask

- (instancetype)initWithHttpTask:(TTHttpTask * _Nullable)task
                     httpHeaders:(NSString * _Nullable)headers
                     originalUrl:(NSString * _Nullable)url
                     redirectUrl:(NSString * _Nullable)location {
    if (self = [super init]) {
        _task = task;
        _originalUrl = [[NSURL alloc] initWithString:url];
        _redirectUrl = [[NSURL alloc] initWithString:location];
        _removedHeaders = [NSMutableArray array];
        _modifiedHeaders = [NSMutableDictionary dictionary];
        [self convertHeaderStringToDictionary:headers];
    }
    return self;
}

- (void)convertHeaderStringToDictionary:(NSString *)headerString {
    if (!headerString) {
        return;
    }

    NSArray *arr = [headerString componentsSeparatedByString: @"\r\n"];
    for (NSString* item in arr) {
        if (!item || !item.length) {
            continue;
        }

        NSRange range = [item rangeOfString:@":"];
        NSString *key = [item substringToIndex:range.location];
        if (!key || !key.length) {
            continue;
        }
        NSString *value = [item substringFromIndex:range.location + 1];

        [self.allHTTPHeaders setValue:value forKey:key];
    }
}

- (void)cancel {
    if (self.task) {
        [self.task cancel];
    }
}

- (NSDictionary<NSString *, NSString *> *)allHTTPHeaderFields {
    return [self.allHTTPHeaders copy];
}

- (NSArray<NSString*> *)currentRemovedHeaders {
    return [self.removedHeaders copy];
}

- (NSDictionary<NSString *, NSString *> *)currentModifiedHeaders {
    return [self.modifiedHeaders copy];
}

- (void)removeHeader:(NSString *)removeHeader {
    [self.allHTTPHeaders removeObjectForKey:removeHeader];
    [self.removedHeaders addObject:removeHeader];
}

- (void)setValue:(NSString * _Nonnull)value
       forHeader:(NSString * _Nonnull)header {
    [self.allHTTPHeaders setValue:value forKey:header];
    [self.modifiedHeaders setValue:value forKey:header];
}

@end
