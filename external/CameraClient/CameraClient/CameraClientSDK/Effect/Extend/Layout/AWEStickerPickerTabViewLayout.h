//
//  AWEStickerPickerTabViewLayout.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerTabViewLayout : NSObject

- (void)categoryViewLayoutWithContainerHeight:(CGFloat)height
                                        title:(nonnull NSString *)title
                                        image:(nonnull UIImage *)image
                                   completion:(nonnull void (^)(CGSize cellSize, CGRect titleFrame, CGRect imageFrame))completion;

@end

NS_ASSUME_NONNULL_END
