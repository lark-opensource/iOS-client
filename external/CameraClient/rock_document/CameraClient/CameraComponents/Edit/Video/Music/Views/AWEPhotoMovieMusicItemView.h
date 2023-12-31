//
//  AWEPhotoMovieMusicItemView.h
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/23.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWEPhotoMovieMusicItemCircleView : UIView
@property (nonatomic, assign) CGFloat cornerRadius;
@end

@interface AWEPhotoMovieMusicItemView : UIButton
- (instancetype)initWithImageSize:(CGSize)size;
- (instancetype)initWithRectangleImageSize:(CGSize)size circleViewOffset:(CGFloat)offset radius:(CGFloat)radius;
- (instancetype)initWithRectangleImageSize:(CGSize)size radius:(CGFloat)radius;
- (void)setSelected:(BOOL)selected;
- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList;
- (void)setImage:(UIImage *)image;
- (void)setMusicBackgroundColor:(UIColor *)backgroundColor;
- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder;
- (void)setDuration:(NSTimeInterval)duration show:(BOOL)show;
@end
