//
//  ACCTextStickerEditWrapedToobarContainer.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCTextStickerEditToolbarType) {
    ACCTextStickerEditToolbarTypeNormal,
    ACCTextStickerEditToolbarTypeSocial,
};

@interface ACCTextStickerEditWrapedToobarContainer : UIView

- (instancetype)initWithFrame:(CGRect)frame
                normalToolBar:(UIView *)normalToolBar
                socialToolBar:(UIView *)socialToolBar;

- (void)switchToToolbarType:(ACCTextStickerEditToolbarType)toolbarType;
@property (nonatomic, assign, readonly) ACCTextStickerEditToolbarType currentToobarType;

@property (nonatomic, strong, readonly) UIView *normalToolBar;
@property (nonatomic, strong, readonly) UIView *socialToolBar;


@end

NS_ASSUME_NONNULL_END
