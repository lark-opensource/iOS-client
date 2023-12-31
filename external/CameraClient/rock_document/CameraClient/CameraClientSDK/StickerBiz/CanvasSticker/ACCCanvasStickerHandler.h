//
//  ACCCanvasStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/28.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCCanvasStickerConfig;
@protocol ACCEditServiceProtocol;

@interface ACCCanvasStickerHandler : ACCStickerHandler

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

- (BOOL)supportCanvas;
- (nullable ACCCanvasStickerConfig *)setupCanvasSticker;

@end

NS_ASSUME_NONNULL_END
