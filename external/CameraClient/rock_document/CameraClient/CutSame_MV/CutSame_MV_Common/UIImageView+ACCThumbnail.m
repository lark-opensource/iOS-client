//
//  UIImageView+AWEThumbnail.m
//  AWEStudio
//
//  Created by Shen Chen on 2019/5/20.
//

#import "UIImageView+ACCThumbnail.h"
#import "ACCThumbnailCache.h"
#import <objc/runtime.h>

@implementation UIImageView (AWEThumbnail)

- (ACCThumbnailRequest *)accThumbnailRequest
{
    return objc_getAssociatedObject(self, @selector(accThumbnailRequest));
}

- (void)setAccThumbnailRequest:(ACCThumbnailRequest *)request
{
    objc_setAssociatedObject(self, @selector(accThumbnailRequest), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)accCancelThumbnailRequests
{
    ACCThumbnailRequest *request = [self accThumbnailRequest];
    if (request) {
        [request cancel];
        [self setAccThumbnailRequest:nil];
    }
}

@end
