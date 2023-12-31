//
//  ACCCustomStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/4/19.
//

#import "ACCStickerHandler.h"
#import "ACCInfoStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCCustomStickerHandler : ACCStickerHandler

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) ACCInfoStickerHandler *infoStickerHandler;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@end

NS_ASSUME_NONNULL_END
