//
//  AWEComposerBeautyTopBarCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/5/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEComposerBeautyTopBarCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *underline;
@property (nonatomic, assign) BOOL shouldShowUnderline;
@property (nonatomic, strong) UIFont *selectedTitleFont;
@property (nonatomic, strong) UIFont *unselectedTitleFont;
@property (nonatomic, strong) UIColor *selectedTitleColor;
@property (nonatomic, strong) UIColor *unselectedTitleColor;

+ (NSString *)identifier;
- (void)updateWithTitle:(NSString *)title selected:(BOOL)selected;
- (void)updateWithUserSelected:(BOOL)userSelected;
- (void)setFlagDotViewHidden:(BOOL)hidden;

@end


NS_ASSUME_NONNULL_END
