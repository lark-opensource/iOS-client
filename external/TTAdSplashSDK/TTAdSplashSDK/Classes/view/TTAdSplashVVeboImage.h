//
//  VVeboImage.h
//  vvebo
//
//  Created by Johnil on 14-3-6.
//  Copyright (c) 2014年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTAdSplashVVeboImage : UIImage

@property (nonatomic,assign) NSInteger currentPlayIndex;
@property (nonatomic,strong) NSData *data;
/** @brief nextImage是否循环的去获取图片
 *  NO：不循环，到最后一帧之后返回nil，YES，循环，到最后一帧之后返回第一帧
 *  defaults NO
 */
@property (nonatomic,assign) BOOL repeatFetchImage;

+ (TTAdSplashVVeboImage *)gifWithData:(NSData *)data;
- (UIImage *)nextImage;
- (int)count;
- (float)frameDuration;
- (void)resumeIndex;
/// 是否还有下一桢
- (BOOL) hasNextImage;
@end
