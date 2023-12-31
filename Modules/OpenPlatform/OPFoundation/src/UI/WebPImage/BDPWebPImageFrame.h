//
//  BDPWebPImageFrame.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/24.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPWebPImageFrame : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) NSTimeInterval duration;

/**
 Create a frame instance with specify image and duration
 
 @param image current frame's image
 @param duration current frame's duration
 @return frame instance
 */
+ (instancetype _Nonnull)frameWithImage:(UIImage * _Nonnull)image duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
