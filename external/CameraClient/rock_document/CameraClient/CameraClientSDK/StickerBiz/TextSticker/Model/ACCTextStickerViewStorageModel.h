//
//  ACCTextStickerStorageModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/16.
//

#import <Mantle/MTLModel.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import "ACCVideoDataClipRangeStorageModel.h"
#import "ACCSerializationProtocol.h"
#import "ACCCommonStickerConfigStorageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerViewStorageModel : MTLModel<ACCSerializationProtocol>

@property (nonatomic, strong) ACCCommonStickerConfigStorageModel *config;

@property (nonatomic, strong, nullable) AWEStoryTextImageModel *textModel;

@property (nonatomic, strong, nullable) NSString *textStickerId;

@property (nonatomic, assign) NSInteger stickerID;

@property (nonatomic, strong, nullable) ACCVideoDataClipRangeStorageModel *timeEditingRange;

@end

NS_ASSUME_NONNULL_END
