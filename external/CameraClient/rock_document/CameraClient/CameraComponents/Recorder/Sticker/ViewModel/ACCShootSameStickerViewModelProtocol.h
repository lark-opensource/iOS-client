//
//  ACCShootSameStickerViewModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/23.
//

#ifndef ACCShootSameStickerViewModelProtocol_h
#define ACCShootSameStickerViewModelProtocol_h

#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCStickerHandler.h"
#import "ACCShootSameStickerHandlerProtocol.h"
#import "ACCShootSameStickerConfigDelegation.h"

@protocol ACCShootSameStickerViewModelProtocol <NSObject>

@property (nonatomic, copy, nullable) void (^onSelectTimeCallback)(UIView * _Nullable);
@property (nonatomic, strong, nullable) NSMutableDictionary<NSNumber *, ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *> *handlers;
@property (nonatomic, weak, nullable) id<ACCShootSameStickerConfigDelegation> configDelegation;

- (void)createHandlersFromPublishModel;
- (void)createStickerViews;
- (void)updateShootSameStickerModel;

@end

#endif // ACCShootSameStickerViewModelProtocol_h
