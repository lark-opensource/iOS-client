//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>



@interface TSPKWebViewUtils : NSObject

+ (instancetype _Nonnull)sharedUtil;

- (void)cacheURL:(nullable NSURL *)request;
- (nullable NSArray *)getCacheURLArray;

@end


