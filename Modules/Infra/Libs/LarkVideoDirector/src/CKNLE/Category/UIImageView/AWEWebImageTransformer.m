//
//  AWEWebImageTransformer.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "AWEWebImageTransformer.h"


@interface AWEWebImageTransformer ()

@property (nonatomic, strong) id <AWEWebImageTransformProtocol> transformer;

@end

@implementation AWEWebImageTransformer

+ (nonnull instancetype)transformWithObject:(id <AWEWebImageTransformProtocol>)transformer
{
    AWEWebImageTransformer *webImageTransformer = [AWEWebImageTransformer new];
    webImageTransformer.transformer = transformer;
    return webImageTransformer;
}

- (NSString *)appendingStringForCacheKey
{
    return [self.transformer appendingStringForCacheKey];
}

- (UIImage *)transformImageBeforeStoreWithImage:(UIImage *)image
{
    return  [self.transformer transformImageBeforeStoreWithImage:image];
}

- (UIImage *)transformImageAfterStoreWithImage:(UIImage *)image
{
    if ([self.transformer respondsToSelector:@selector(transformImageAfterStoreWithImage:)]) {
        return [self.transformer transformImageAfterStoreWithImage:image];
    }
    return image;
}

@end
