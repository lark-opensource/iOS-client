//
//  ACCImageAlbumEditPageControl.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/22.
//

#import <UIKit/UIKit.h>

#import "ACCImageAlbumPageControlProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumEditPageControl : UIView <ACCImageAlbumPageControlProtocol>

/// default is 0
@property (nonatomic, assign) NSInteger numberOfPages;

/// default is 0. Value is pinned to 0..numberOfPages-1
@property (nonatomic, assign) NSInteger currentPage;

@end

NS_ASSUME_NONNULL_END
