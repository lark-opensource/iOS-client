//
//  CAKAlbumSelectAlbumButton.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import <UIKit/UIKit.h>
#import "CAKAnimatedButton.h"

@interface CAKAlbumSelectAlbumButton : CAKAnimatedButton

@property (nonatomic, strong, nullable) UILabel *leftLabel;
@property (nonatomic, strong, nullable) UIImageView *rightImageView;

- (instancetype _Nonnull)initWithType:(CAKAnimatedButtonType)btnType;

- (instancetype _Nonnull)initWithType:(CAKAnimatedButtonType)btnType titleAndImageInterval:(CGFloat)interval;

@end
