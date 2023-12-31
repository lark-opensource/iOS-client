//
//  VEDMaskRotateGesture.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskRotateGesture : NSObject

@property (nonatomic, weak) VEDMaskDrawView *drawView;

@property (nonatomic, assign) CGFloat beginRotation;

// MARK:- Rotate Gesture
- (void)didRotateWithRotate:(UIRotationGestureRecognizer *)rotate;



@end

NS_ASSUME_NONNULL_END
