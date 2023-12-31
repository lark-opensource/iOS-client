//
//  BDBlockTransformer.m
//  Pods
//
//  Created by jiangliancheng on 2017/4/23.
//
//

#import "BDBlockTransformer.h"

@interface BDBlockTransformer ()

@property (nonatomic, copy) BDTransformBlock block;

@end

@implementation BDBlockTransformer

- (nonnull NSString *)appendingStringForCacheKey {
    return @"BDBlockTransformer";
}

+ (instancetype)transformWithBlock:(BDTransformBlock)block;
{
    BDBlockTransformer *transformer = [BDBlockTransformer new];
    transformer.block = block;
    return transformer;
}

- (nullable UIImage *)transformImageAfterStoreWithImage:(nullable UIImage *)image;
{
    if (self.block) {
        return self.block(image);
    }
    return image;
}

- (BOOL)isAppliedToThumbnail {
    return NO;
}
@end
