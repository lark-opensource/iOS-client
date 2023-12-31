//
//  AWEVideoPublishMusicSelectHeaderView.h
//  AWEStudio
//
//  Created by Nero Li on 2019/1/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEMusicEditorCollectionHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AWEVideoPublishMusicSelectHeaderViewDelegate <NSObject>

- (void)musicLibraryIconDidTapped;

@end

@interface AWEVideoPublishMusicSelectHeaderView : UICollectionReusableView
@property (nonatomic, weak) id<AWEVideoPublishMusicSelectHeaderViewDelegate> delegate;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) AWEMusicEditorCollectionHeaderView *dotSeparatorView;
- (void)updateImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
