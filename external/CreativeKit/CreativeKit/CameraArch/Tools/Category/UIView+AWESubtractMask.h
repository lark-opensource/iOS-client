//
//  UIView+AWESubtractMask.h
//  Pods
//
//  Created by chengfei xiao on 2019/3/3.
//

#import <UIKit/UIKit.h>

@interface UIView (MFSubtractMask)

/**
 Set the skeleton mask view, this method essentially sets the maskView
 If the content of the boarding map is updated, you need to manually call the setter method again
 */
- (void)awe_setSubtractMaskView:(UIView *)view;

/**
 Get the skeleton mask view for dynamically modifying some of the mask's properties
 */
- (UIView *)awe_subtractMaskView;

@end
