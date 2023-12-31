//
//  ECOCookieStorage.h
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ECOCookieStorage <NSObject>

/// Get cookies from url, like HTTPCookieStoragte.cookies(for:)
- (NSArray<NSHTTPCookie *> *)cookiesForURL: (NSURL *)url;

/// Save cookies to storage
- (void)saveCookies:(NSArray<NSHTTPCookie *> *)cookies url:(nullable NSURL *)url NS_SWIFT_NAME(saveCookies(_:url:));

/// Save cookies from response
- (void)saveCookieWithResponse:(NSHTTPURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
