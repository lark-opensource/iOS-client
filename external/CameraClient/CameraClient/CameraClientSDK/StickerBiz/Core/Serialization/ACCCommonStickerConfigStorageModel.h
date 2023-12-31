//
//  ACCCommonStickerConfigStorageModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import <Mantle/MTLModel.h>
#import "ACCStickerBizDefines.h"
#import "ACCStickerGeometryModelStorageModel.h"
#import "ACCStickerTimeRangeModelStorageModel.h"
#import "ACCSerializationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCCommonStickerConfigStorageModel : MTLModel<ACCSerializationProtocol>

@property (nonatomic, strong) id typeId;

@property (nonatomic, strong) id hierarchyId;

@property (nonatomic, assign) CGFloat minimumScale;

@property (nonatomic, assign) CGFloat maximumScale;

@property (nonatomic, strong, nullable) ACCStickerGeometryModelStorageModel *geometryModel;

@property (nonatomic, strong) ACCStickerTimeRangeModelStorageModel *timeRangeModel;

@property (nonatomic, assign) UIEdgeInsets boxPadding;

@property (nonatomic, assign) UIEdgeInsets boxMargin;

@property (nonatomic, assign) BOOL changeAnchorForRotateAndScale;

#pragma mark -
@property (nonatomic, assign) ACCStickerContainerFeature preferredContainerFeature;

@property (nonatomic, strong) NSValue *gestureInvalidFrameValue;

@end

NS_ASSUME_NONNULL_END
