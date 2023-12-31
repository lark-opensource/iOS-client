//
//  VEDMaskPanGestureHandler.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskPanGestureHandler : NSObject

@property (nonatomic, weak) VEDMaskDrawView *drawView;

@property (nonatomic, assign) CGPoint beginPanPoint;

// MARK:- Pan Gesture
- (void)didPanWithGesture:(UIPanGestureRecognizer *)pan;


@end

NS_ASSUME_NONNULL_END
