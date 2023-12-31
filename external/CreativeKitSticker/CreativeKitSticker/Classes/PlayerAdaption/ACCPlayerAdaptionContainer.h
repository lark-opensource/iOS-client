//
//  ACCPlayerAdaptionContainer.h
//  CameraClient
//
//  Created by guocheng on 2020/5/26.
//

#import "ACCPlayerAdaptionContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPlayerAdaptionContainer : UIView <ACCPlayerAdaptionContainerProtocol>

@property (nonatomic, assign) BOOL ignoreMaskRadiusForXScreen;

- (void)updateContainerFrame:(CGRect)containerFrame playerFrame:(CGRect)playerFrame allowMask:(BOOL)allowMask;

- (void)configWithPlayerFrame:(CGRect)playerFrame allowMask:(BOOL)allowMask NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
