//
//  ACCStickerLimitEdgeView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2021/1/29.
//

#import <UIKit/UIKit.h>
#import <CreativeKitSticker/ACCStickerContainerPluginProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerLimitEdgeView : UIView<ACCStickerGestureResponsiblePluginProtocol>

@property (nonatomic, assign) CGSize contentSize;

@end

NS_ASSUME_NONNULL_END
