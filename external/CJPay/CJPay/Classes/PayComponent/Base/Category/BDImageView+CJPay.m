//
//  BDImageView+CJPay.m
//  Pods
//
//  Created by 易培淮 on 2021/5/21.
//

#import "BDImageView+CJPay.h"
#import "UIImage+CJPay.h"
#import "NSBundle+CJPay.h"
#import <BDWebImage/BDWebImage.h>

@implementation BDImageView(CJPay)


- (void)cj_loadGifAndOnceLoop:(NSString *)gifName
                     duration:(NSTimeInterval) duration {
    self.infinityLoop = NO;
    self.customLoop = 1;
    self.autoPlayAnimatedImage = YES;
    self.animationDuration = duration;
    [self p_baseLoadGif:gifName];
}

- (void)cj_loadGifAndOnceLoopWithURL:(NSString *)url
                            duration:(NSTimeInterval)duration {
    self.infinityLoop = NO;
    self.customLoop = 1;
    self.autoPlayAnimatedImage = YES;
    self.animationDuration = duration;
    [self p_baseLoadGifWithURL:url];
}

- (void)cj_loadGifAndInfinityLoop:(NSString *)gifName
                         duration:(NSTimeInterval) duration {
    self.infinityLoop = YES;
    self.customLoop = 0;
    self.autoPlayAnimatedImage = YES;
    self.animationDuration = duration;
    [self p_baseLoadGif:gifName];
}

- (void)cj_loadGifAndInfinityLoopWithURL:(NSString *)url
                                duration:(NSTimeInterval)duration {
    self.infinityLoop = YES;
    self.customLoop = 0;
    self.autoPlayAnimatedImage = YES;
    self.animationDuration = duration;
    [self p_baseLoadGifWithURL:url];
}

- (void)p_baseLoadGif:(NSString *)gifName {
    static NSBundle *bundle = nil;
    if (!bundle) {
        bundle = [NSBundle cj_customPayBundle];
    }
    NSDataAsset *dataset = [[NSDataAsset alloc] initWithName:gifName bundle:bundle];
    self.image = [BDImage imageWithData:dataset.data];
}

- (void)p_baseLoadGifWithURL:(NSString *)url {
    [self bd_setImageWithURL:[NSURL URLWithString:url]];
}

@end
