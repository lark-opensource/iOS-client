//
//  IESLiveResouceBundle+Image.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle+Image.h"
#import "IESLiveResouceManager.h"

@implementation IESLiveResouceBundle (Image)

- (UIImage * (^)(NSString *key))image {
    return ^(NSString *key) {
        if (key) {
            UIImage *image = [self objectForKey:key type:@"image"];
            return image;
        }
        return (UIImage *)nil;
    };
}

@end
