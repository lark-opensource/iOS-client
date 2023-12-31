//
//  CAKModalTransitionDelegate.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CAKSwipeInteractionController.h"

@interface CAKModalTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nullable) CAKSwipeInteractionController *swipeInteractionController;

@end
