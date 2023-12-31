//
//  CAKAlbumPreviewPageBottomViewProtocol.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by qiyang on 2020/4/8.
//

#import <Foundation/Foundation.h>

@protocol CAKAlbumPreviewPageBottomViewProtocol <NSObject>

@property (nonatomic, strong, nullable) UIButton *selectPhotoButton;
@property (nonatomic, strong, nullable) UILabel *selectHintLabel;
@property (nonatomic, strong, nullable) UIButton *nextButton;
@property (nonatomic, strong, nullable) UIVisualEffectView *effectView;

- (void)updateSelectPhotoStatus:(BOOL)isSelected;
- (void)updateNextButtonStatus:(BOOL)enableNext;

@end
