//
//  ACCBaseStickerView.h
//  CameraClient
//
//  Created by guocheng on 2020/5/27.
//

#import "ACCStickerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerConfig;

@interface ACCBaseStickerView : UIView <ACCStickerProtocol>

@property (nonatomic, strong, readonly) ACCStickerConfig *config;
@property (nonatomic, assign, readonly) BOOL isSelected;
@property (nonatomic, assign) BOOL foreverHidden;

- (void)doSelect;
- (void)doDeselect;

@end

NS_ASSUME_NONNULL_END
