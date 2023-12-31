//
//  IESForestImagePreloader.m
//  IESGeckoKit-c0aad4e9
//
//  Created by ruichao xue on 2022/9/17.
//

#import "IESForestImagePreloader.h"

#import <BDWebImage/BDWebImage.h>

@implementation IESForestImagePreloader

+ (void)preloadWithURLString:(NSString * _Nonnull)urlString
                enableMemory:(BOOL)enableMemory;
{
    NSURL *url = [NSURL URLWithString:urlString];
    BDImageRequestOptions options = enableMemory ? BDImageRequestDefaultOptions : BDImageRequestIgnoreImage;
    [[BDWebImageManager sharedManager] prefetchImageWithURL:url cacheName:urlString category:nil options:options];
}

+ (BOOL)hasCacheImageForKey:(NSString *)key
{
    return [[BDWebImageManager sharedManager].imageCache containsImageForKey:key];
}

@end
