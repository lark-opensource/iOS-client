//
//  ACCInteractionView.h
//  CameraClient-Pods-Aweme
//
//  Created by lihui on 2019/11/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCInteractionView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, copy, nullable) dispatch_block_t interactionBlock;

@end

NS_ASSUME_NONNULL_END
