//
//  CAKAlbumTransitionInteractionController.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/4.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumTransitionContextProvider.h"
#import "CAKAlbumTransitionDelegateProtocol.h"

@interface CAKAlbumTransitionInteractionController : NSObject <UIViewControllerInteractiveTransitioning>

+ (instancetype _Nonnull)instanceWithContextProvider:(id<CAKAlbumTransitionContextProvider> _Nullable)provider transitionDelegate:(id<CAKAlbumTransitionDelegateProtocol> _Nullable)transitionDelegate;

@end

