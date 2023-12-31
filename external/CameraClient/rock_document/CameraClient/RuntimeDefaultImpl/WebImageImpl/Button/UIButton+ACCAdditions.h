//
//  UIButton+ACCAdditions.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <UIKit/UIKit.h>
#import "UIImageView+ACCWebImage.h"

@interface UIButton (ACCWebImage)

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          forState:(UIControlState)state
                       placeholder:(nullable UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setBackgroundImageWithURLArray:(nullable NSArray *)imageUrlArray
                                    forState:(UIControlState)state
                                 placeholder:(nullable UIImage *)placeholder;

@end

