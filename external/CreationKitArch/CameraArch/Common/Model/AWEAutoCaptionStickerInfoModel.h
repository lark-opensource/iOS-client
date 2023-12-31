//
//  AWEAutoCaptionStickerInfoModel.h
//  CameraClientTikTok
//
//  Created by liuqing on 2021/2/5.
//

#import <Mantle/Mantle.h>
#import "AWEStudioCaptionModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AWEInteractionAutoCaptionStickerLocationType) {
    AWEInteractionAutoCaptionStickerLocationTypeLeftTop = 0,
    AWEInteractionAutoCaptionStickerLocationTypeMiddleTop = 1,
    AWEInteractionAutoCaptionStickerLocationTypeRightTop = 2,
    AWEInteractionAutoCaptionStickerLocationTypeLeftMiddle = 3,
    AWEInteractionAutoCaptionStickerLocationTypeMiddleMiddle = 4,
    AWEInteractionAutoCaptionStickerLocationTypeRightMiddle = 5,
    AWEInteractionAutoCaptionStickerLocationTypeLeftBottom = 6,
    AWEInteractionAutoCaptionStickerLocationTypeMiddleBottom = 7,
    AWEInteractionAutoCaptionStickerLocationTypeRightBottom = 8,
};

FOUNDATION_EXPORT NSString * const AWEInteractionAutoCaptionStickerCaptionsKey;

@interface AWEAutoCaptionUrlModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSArray<NSString *> *urlList;

@end

@interface AWEAutoCaptionInfoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *language;
@property (nonatomic, strong) AWEAutoCaptionUrlModel *url;

@end

@interface AWEAutoCaptionStickerInfoModel : MTLModel<MTLJSONSerializing>

// both
@property (nonatomic, assign) AWEInteractionAutoCaptionStickerLocationType locationType;

// creation
@property (nonatomic, copy) NSString *audioUri;
@property (nonatomic, copy) NSString *taskId;
@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> *captions;

// consumption
@property (nonatomic, copy) NSArray<AWEAutoCaptionInfoModel *> *captionInfos;

@end

NS_ASSUME_NONNULL_END
