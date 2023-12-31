//
//  ACCStickerCopyingProtocol.h
//  CameraClient
//
//  Created by liuqing on 2020/6/15.
//

#import <Foundation/Foundation.h>

@protocol ACCStickerContainerConfigProtocol;
@class ACCBaseStickerView, ACCStickerGeometryModel, ACCStickerTimeRangeModel, ACCStickerContainerView;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerCopyingContextDelegate <NSObject>

- (CGRect)mediaSmallMediaContainerFrame;

@end

@protocol ACCStickerCopyingContextProtocol <NSObject>

- (CGSize)containerSizeFromOriginSize:(CGSize)size;

@end

@protocol ACCStickerCopyingProtocol <NSObject>

@optional

- (instancetype)copyForContext:(id)contextId;

- (instancetype)copyForContext:(id)contextId modConfig:(nullable void(^)(NSObject<ACCStickerContainerConfigProtocol> * config))modConfig modContainer:(nullable void (^)(ACCStickerContainerView *stickerContainerView))modContainer enumerateStickerUsingBlock:(nullable void (^)(__kindof ACCBaseStickerView *stickerView, NSUInteger idx, ACCStickerGeometryModel *geometryModel, ACCStickerTimeRangeModel *timeRangeModel))stickerEnumerator;

- (void)updateWithInstance:(id)instance context:(id)contextId;

@end

NS_ASSUME_NONNULL_END
