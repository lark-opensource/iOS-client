//
//  BDBaseTransformer.m
//  Pods
//
//  Created by jiangliancheng on 2017/4/23.
//
//

#import "BDBaseTransformer.h"

@implementation BDBaseTransformer

#pragma mark - defaultImplement

- (nonnull NSString *)appendingStringForCacheKey
{
    return @"";
}

- (nullable UIImage *)transformImageBeforeStoreWithImage:(nullable UIImage *)image
{
    return image;
}

- (nullable UIImage *)transformImageAfterStoreWithImage:(nullable UIImage *)image
{
    return image;
}

- (nullable NSDictionary *)transformImageRecoder {
    return @{};
}

- (BOOL)isAppliedToThumbnail {
    [NSException raise:NSGenericException format:@"Please use subclass instance to call this method!"];
    return NO;
}
@end
