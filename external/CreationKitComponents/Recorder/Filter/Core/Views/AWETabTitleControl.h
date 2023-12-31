//
//  AWETabTitleControl.h
//  AWEStudio
//
//Created by Li Yansong on July 27, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <UIKit/UIKit.h>

@interface AWETabTitleControl : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, assign) CGFloat indicatorWidth;
@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, strong) UIFont *unselectedFont;

- (void)showYellowDot:(BOOL)show;

+ (CGSize)collectionView:(UICollectionView *)collectionView sizeForTabTitleControlWithTitle:(NSString *)title font:(UIFont *)font;

@end
