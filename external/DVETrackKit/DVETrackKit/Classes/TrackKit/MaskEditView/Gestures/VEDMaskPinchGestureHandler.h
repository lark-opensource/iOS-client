//
//  VEDMaskPinchGestureHandler.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskPinchGestureHandler : NSObject

@property (nonatomic, weak) VEDMaskDrawView *drawView;

@property (nonatomic, assign) CGFloat beginWidth;

@property (nonatomic, assign) CGFloat beginHeight;

// MARK:- Pinch Gesture
- (void)didPinchWithPinchRecognizer:(UIPinchGestureRecognizer *)pinch;


@end

NS_ASSUME_NONNULL_END
