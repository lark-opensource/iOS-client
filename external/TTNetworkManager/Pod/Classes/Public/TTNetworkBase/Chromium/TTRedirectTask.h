//
//  TTRedirectTask.h
//  TTNetworkManager
//
//  Created by bytedance on 2022/9/5.
//

#import <Foundation/Foundation.h>

@class TTHttpTask;

@interface TTRedirectTask : NSObject

@property (nonatomic, nonnull, readonly, copy) NSURL *originalUrl;

@property (nonnull, copy) NSURL *redirectUrl;

@property (nonatomic, nullable, readonly, copy) NSDictionary<NSString *, NSString *> *allHTTPHeaderFields;

@property (nonatomic, nullable, readonly, copy) NSArray<NSString *> *currentRemovedHeaders;

@property (nonatomic, nullable, readonly, copy) NSDictionary<NSString *, NSString *> *currentModifiedHeaders;

- (instancetype _Nullable)initWithHttpTask:(TTHttpTask * _Nullable)task
                               httpHeaders:(NSString * _Nullable)headers
                               originalUrl:(NSString * _Nullable)url
                               redirectUrl:(NSString * _Nullable)location;

- (void)cancel;

- (void)removeHeader:(NSString * _Nonnull)removeHeader;

- (void)setValue:(NSString * _Nonnull)value
       forHeader:(NSString * _Nonnull)header;

@end
