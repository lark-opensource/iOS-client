//
//  ACCStickerContainerView+CameraClient.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/13.
//

#import <CreativeKitSticker/ACCStickerContainerView.h>
#import "ACCEditorStickerArtboardProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerContainerView (CameraClient)<ACCEditorStickerArtboardProtocol>

@property (nonatomic, strong) UIImageView *selectStickerDurationTmpSnapshotView;

// will use stickerViewList first, if no stickerViewList is setted, use stickerContentView backup
- (UIView <ACCStickerSelectTimeRangeProtocol> *)stickerContentView;
- (NSArray <UIView <ACCSelectTimeRangeStickerProtocol> *> *)stickerViewList;

- (void)generateTmpSnapshotView;

@property (nonatomic, assign) NSInteger hierarchy;
@property (nonatomic, assign) CGSize mediaActualSize;// 实际的媒体size

@end

NS_ASSUME_NONNULL_END
