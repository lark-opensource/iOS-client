//
//  CAKAlbumTransitionDelegateProtocol.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumTransitionContextProvider.h"

@protocol CAKAlbumTransitionDelegateProtocol <NSObject>

@property (nonatomic, weak, nullable) UIViewController *outterViewController;
@property (nonatomic, weak, nullable) UIViewController *innerViewController;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, weak, nullable) id<UIViewControllerContextTransitioning> currentTransitioningContext;
@property (nonatomic, strong, nullable) id<CAKAlbumTransitionContextProvider> contextProvider;

@end
