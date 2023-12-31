//
//  AWEASMusicCategoryCollectionViewCell.h
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCVideoMusicCategoryModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWEASMusicCategoryCollectionViewCell : UICollectionViewCell

+ (NSString *)identifier;

+ (CGFloat)recommendedHeight;

- (void)configWithMusicCategoryModel:(ACCVideoMusicCategoryModel *)model;

@end

NS_ASSUME_NONNULL_END
