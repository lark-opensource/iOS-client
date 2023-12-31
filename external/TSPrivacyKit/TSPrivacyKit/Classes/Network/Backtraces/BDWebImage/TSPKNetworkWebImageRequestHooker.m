//
//  TSPKNetworkWebImageRequestHooker.m
//  Musically
//
//  Created by admin on 2023/1/16.
//

#import "TSPKNetworkWebImageRequestHooker.h"
#import <BDWebImage/BDWebImageManager.h>
#import "NSObject+TSAddition.h"

@implementation BDWebImageManager (TSPKNetworkHooker)

+ (void)tspk_network_preload {
    [self ts_swizzleInstanceMethod:@selector(requestImage:) with:@selector(tspk_network_requestImage:)];
}

- (void)tspk_network_requestImage:(BDWebImageRequest *)request {
    [TSPKNetworkWebImageRequestHooker reportWithBacktrace:@"web_image" url:request.currentRequestURL];
    [self tspk_network_requestImage:request];
}

@end

@implementation TSPKNetworkWebImageRequestHooker

+ (void)preload {
    [BDWebImageManager tspk_network_preload];
}

@end
