//
//  UIButton+AWEAdditions.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <UIKit/UIKit.h>
#import "UIImageView+AWEWebImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (AWEWebImage)

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          forState:(UIControlState)state
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setBackgroundImageWithURLArray:(nullable NSArray *)imageUrlArray
                                    forState:(UIControlState)state
                                 placeholder:(nullable UIImage *)placeholder;

@end

NS_ASSUME_NONNULL_END
