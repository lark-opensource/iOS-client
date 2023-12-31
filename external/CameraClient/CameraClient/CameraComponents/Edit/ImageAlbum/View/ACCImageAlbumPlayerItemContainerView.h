//
//  ACCImageAlbumPlayerItemContainerView.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/25.
//

#import <UIKit/UIKit.h>


@interface ACCImageAlbumPlayerItemContainerView : UIView

- (instancetype)initWithContainerSize:(CGSize)containerSize;
- (void)updateRenderImage:(UIImage *_Nullable)image;
- (void)updateEditingView:(UIView *_Nullable)editingView;

@property (nonatomic, strong, readonly) UIImage *_Nullable renderedImage;
@property (nonatomic, strong, readonly) UIView *_Nonnull customerContentView;

@end

