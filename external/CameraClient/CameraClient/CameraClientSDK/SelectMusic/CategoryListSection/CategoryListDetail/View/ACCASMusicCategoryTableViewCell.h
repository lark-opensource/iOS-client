//
//  ACCASMusicCategoryTableViewCell.h
//  CameraClient
//
//  Created by 李茂琦 on 2018/9/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCVideoMusicCategoryModel;

@interface ACCASMusicCategoryTableViewCell : UITableViewCell

+ (NSString *)identifier;

+ (CGFloat)recommendedHeight;

- (void)configWithMusicCategoryModel:(ACCVideoMusicCategoryModel *)model;

@end
