//
//  AWEComposerBeautySwitchCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEComposerBeautySwitchCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *switchLabel;

- (void)updateSwitchViewIfIsOn:(BOOL)isOn;

@end

NS_ASSUME_NONNULL_END
