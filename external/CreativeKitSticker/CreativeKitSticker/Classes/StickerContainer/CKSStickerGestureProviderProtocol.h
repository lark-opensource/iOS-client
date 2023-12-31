//
//  CKSStickerGestureProviderProtocol.h
//  CreativeKitSticker-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/12.
//

#import <Foundation/Foundation.h>
#import "ACCStickerContainerProtocol.h"
#import "ACCStickerEventFlowProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CKSStickerGestureProviderProtocol <NSObject>

- (instancetype)initWithWeakReferenceOfStickerContainer:(id<ACCStickerContainerProtocol, ACCStickerEventFlowProtocol>)stickerContainer;

- (UIView *)gestureView;

@end

NS_ASSUME_NONNULL_END
