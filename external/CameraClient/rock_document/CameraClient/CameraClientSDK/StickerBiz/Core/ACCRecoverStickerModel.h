//
//  ACCRecoverStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/9/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESInfoSticker, AWEInteractionStickerModel;

typedef NS_ENUM(NSInteger, ACCRecoverStickerSourceType) {
    ACCRecoverStickerSourceTypeDraft = 0,
    ACCRecoverStickerSourceTypeBackup = 1,
    ACCRecoverStickerSourceTypeRecord = 2
};

@interface ACCRecoverStickerModel : NSObject

@property (nonatomic, strong) IESInfoSticker *infoSticker;
@property (nonatomic, strong) AWEInteractionStickerModel *interactionSticker;
@property (nonatomic, assign) ACCRecoverStickerSourceType sourceType;// 是否从拍摄页带来

@end

NS_ASSUME_NONNULL_END
