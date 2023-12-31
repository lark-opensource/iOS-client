//
//  ACCWebImageTransformer.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "ACCWebImageTransformer.h"


@interface ACCWebImageTransformer ()

@property (nonatomic, strong) id <ACCWebImageTransformProtocol> transformer;

@end

@implementation ACCWebImageTransformer

+ (nonnull instancetype)transformWithObject:(id <ACCWebImageTransformProtocol>)transformer
{
    ACCWebImageTransformer *webImageTransformer = [ACCWebImageTransformer new];
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
