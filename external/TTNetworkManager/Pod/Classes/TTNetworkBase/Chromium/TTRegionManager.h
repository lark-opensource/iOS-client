//
//  TTRegionManager.h
//  TTNetworkManager
//
//  Created by bytedance on 2021/6/30.
//

#import <Foundation/Foundation.h>

#import "TTHttpResponseChromium.h"
#import "TTNetworkDefine.h"
#import "net/url_request/url_fetcher.h"

#define kStoreCountryCodeCookie "store-country-code="
#define kStoreCountryCodeSrcCookie "store-country-code-src="
#define kStoreRegionCookie "store-region="
#define kStoreRegionSrcCookie "store-region-src="

@interface TTRegionManager : NSObject

+ (NSString *) getdomainRegionConfig;

#ifndef OC_DISABLE_STORE_IDC
+(void)updateStoreRegionConfigFromResponse:(const net::URLFetcher*)response responseBody:(NSData *)responseBody url:(NSURL *)url;
#endif

@end
