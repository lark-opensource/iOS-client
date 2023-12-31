//
//  ACCCircleItemCell.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/8.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCircleItemCell : UICollectionViewCell
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong, readonly) UIVisualEffectView *effectView;
@end

@interface ACCCircleImageItemCell : ACCCircleItemCell
@property (nonatomic, strong, readonly) UIImageView *overlay;
@property (nonatomic, strong, readonly) UIImageView *overlayImageView;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign) BOOL isHome;
@property (nonatomic, assign) BOOL useRatioImage;
@property (nonatomic, assign) CGFloat imageRatio;
@end

@interface ACCCircleHomeItemCell : ACCCircleImageItemCell

@end

@interface ACCCircleResourceItemCell : ACCCircleImageItemCell
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL showProgress;
@property (nonatomic, assign) CGFloat imageScale;
- (void)setShowProgress:(BOOL)showProgress animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
