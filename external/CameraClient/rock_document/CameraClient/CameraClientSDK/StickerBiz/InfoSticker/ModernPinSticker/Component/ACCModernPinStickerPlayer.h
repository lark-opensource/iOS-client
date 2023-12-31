//
//  ACCModernPinStickerPlayer.h
//  CameraClient
//
//  Created by Pinka.
//

#import <Foundation/Foundation.h>
#import "ACCModernPinStickerViewControllerInputData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCModernPinStickerPlayer : NSObject

@property (nonatomic, strong) ACCModernPinStickerViewControllerInputData *inputData;
@property (nonatomic, strong) UIView *playerContainer;

/// 实际上就是投票贴纸的截图
@property (nonatomic, strong) UIImageView *interactionImageView;

@property (nonatomic, copy) void (^activeStickerBlock)(CGFloat startTime, CGFloat duration,CGFloat currTime);

- (void)configWhenContainerDidAppear;

- (void)configWhenContainerWillDisappear;
    
- (void)setPlayerContainerFrame:(CGRect)frame content:(UIView *)content;

@end

NS_ASSUME_NONNULL_END
