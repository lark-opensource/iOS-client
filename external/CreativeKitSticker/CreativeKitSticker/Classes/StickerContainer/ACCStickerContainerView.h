//
//  ACCStickerContainerView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/7.
//

#import "ACCPlayerAdaptionContainer.h"
#import "ACCStickerContainerProtocol.h"
#import "ACCStickerContainerConfigProtocol.h"
#import "ACCStickerEventFlowProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerContainerView;

@protocol ACCStickerContainerDelegate <NSObject>

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureStarted:(UIGestureRecognizer *)gesture onView:(UIView *)targetView;
- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureEnded:(UIGestureRecognizer *)gesture onView:(UIView *)targetView;
- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer gesture:(UIGestureRecognizer *)gesture;

@end

@interface ACCStickerContainerView : ACCPlayerAdaptionContainer <ACCStickerContainerProtocol, ACCStickerEventFlowProtocol>

@property (nonatomic, weak) id<ACCStickerContainerDelegate> delegate;
@property (nonatomic, assign) BOOL shouldHandleGesture; // should use internal gesutre; Default is NO

@property (nonatomic, strong, readonly) NSArray <__kindof id <ACCStickerContainerPluginProtocol>> *plugins;

// init
- (instancetype)initWithFrame:(CGRect)frame config:(NSObject<ACCStickerContainerConfigProtocol> *)config NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

#pragma mark - Tools
- (void)doDeselectAllStickers;

@end

@interface ACCStickerContainerView (Deprecated)

- (UIImage * __nullable)generateImage;
- (UIImage * __nullable)generateImageWithStickerTypeID:(id)typeID;

@end

NS_ASSUME_NONNULL_END
