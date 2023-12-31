//
//  ACCImageAlbumEditPlayerItemCell.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumEditPlayerItemCell : UICollectionViewCell

- (void)reloadWithPreviewView:(UIView *)previewView;

- (void)reloadCurrentPreviewViewIfNeed;

@end

NS_ASSUME_NONNULL_END
