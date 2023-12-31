//
//  BDWebImageManager+Private.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDWebImageManager.h"


@interface BDWebImageManager (Private)

- (void)_cancelRequest:(BDWebImageRequest *)request;
- (NSString *)requestKeyWithURL:(NSURL *)url;

@end
