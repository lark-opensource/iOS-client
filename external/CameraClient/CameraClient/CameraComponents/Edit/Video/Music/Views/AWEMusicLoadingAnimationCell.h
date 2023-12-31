//
//  AWEMusicLoadingAnimationCell.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by chengfei xiao on 2019/3/17.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface AWEMusicLoadingAnimationCell : UICollectionViewCell
// 整个动画填充满cell view
@property (nonatomic, assign) BOOL animationFillToContent;
- (void)startAnimating;

- (void)stopAnimating;
@end

NS_ASSUME_NONNULL_END
