//
//  AWECustomStickerEditContainer.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/17.
//

#import <UIKit/UIKit.h>

@protocol AWECustomStickerEditContainerDelegate <NSObject>

- (void)processAnimationCompleted;

@end

@interface AWECustomStickerEditContainer : UIView

@property (nonatomic, weak) id<AWECustomStickerEditContainerDelegate> delegate;

- (instancetype)initWithImage:(UIImage *)image aspectRatio:(CGFloat)aspectRatio;

- (void)prepareForProcess;

- (void)processWithResult:(UIImage *)image points:(NSArray<NSArray *> *)points maxRect:(CGRect)maxRect;

- (void)applyUseProcessed:(BOOL)useUseProcessed;

+ (CGSize)containerSizeWithImageSize:(CGSize)imageSize maxSize:(CGSize)maxSize;

+ (CGFloat)aspectRatioWithImageSize:(CGSize)imageSize containerSize:(CGSize)containerSize;

@end
