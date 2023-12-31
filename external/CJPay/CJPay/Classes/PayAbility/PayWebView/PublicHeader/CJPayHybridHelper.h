//
//  CJPayHybridHelper.h
//  cjpaysandbox
//
//  Created by ByteDance on 2023/4/26.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface CJPayHybridHelper : NSObject

+ (BOOL)hasHybridPlugin;

+ (nullable UIView *)createHybridView:(nonnull NSString *)scheme
                           wkDelegate:(nullable id)delegate
                          initialData:(nullable NSDictionary *)params;

+ (nullable WKWebView *)getRawWebview:(UIView *)hybridView;

+ (nullable NSString *)getContainerID:(UIView *)container;

+ (void)sendEvent:(nonnull NSString *)event params:(nullable NSDictionary*)data container:(nonnull UIView *)view;

@end

NS_ASSUME_NONNULL_END
