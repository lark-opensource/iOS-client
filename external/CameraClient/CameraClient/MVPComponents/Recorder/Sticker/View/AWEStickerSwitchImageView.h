//
//  AWEStickerSwitchImageView.h
//  Aweme
//
//  Created by 郝一鹏 on 2017/7/4.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreativeKit/ACCAnimatedButton.h>
#import <BDWebImage/BDImageView.h>

@interface AWEStickerSwitchImageView : BDImageView

@property (nonatomic, strong) BDImageView *coverMarkImgView;
@property (nonatomic, strong) UIImage *defaultImage;

- (void)replaceCoverImageWithImage:(UIImage *)newImage isDynamic:(BOOL)isDynamic;

@end
