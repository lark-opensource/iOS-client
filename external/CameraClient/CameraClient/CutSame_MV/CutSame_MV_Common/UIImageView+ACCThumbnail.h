//
//  UIImageView+AWEThumbnail.h
//  AWEStudio
//
//  Created by Shen Chen on 2019/5/20.
//

#import <UIKit/UIKit.h>

@class ACCThumbnailRequest;

@interface UIImageView (ACCThumbnail)

- (void)accCancelThumbnailRequests;

- (ACCThumbnailRequest *)accThumbnailRequest;
- (void)setAccThumbnailRequest:(ACCThumbnailRequest *)request;

@end
