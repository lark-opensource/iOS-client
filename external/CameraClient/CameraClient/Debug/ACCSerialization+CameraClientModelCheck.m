//
//  ACCSerialization+CameraClientModelCheck.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2021/2/9.
//
#if DEBUG || INHOUSE_TARGET

#import "ACCSerialization+CameraClientModelCheck.h"

#import "ACCTextStickerViewStorageModel.h"
#import "ACCTextStickerView.h"

#import "ACCStickerGeometryModelStorageModel.h"
#import <CreativeKitSticker/ACCStickerGeometryModel.h>

#import "ACCStickerTimeRangeModelStorageModel.h"
#import <CreativeKitSticker/ACCStickerTimeRangeModel.h>

#import "ACCCommonStickerConfigStorageModel.h"
#import "ACCCommonStickerConfig.h"

#import "ACCVideoDataClipRangeStorageModel.h"
#import <TTVideoEditor/IESMMVideoDataClipRange.h>

@implementation ACCSerialization (CameraClientModelCheck)

+ (void)acc_textStickerStorageModelCheck
{
    ACC_SERIALIZATION_KEY_EQUAL(ACCTextStickerViewStorageModel*, ACCTextStickerView*, textStickerId);
    ACC_SERIALIZATION_KEY_EQUAL(ACCTextStickerViewStorageModel*, ACCTextStickerView*, textModel);
    ACC_SERIALIZATION_KEY_EQUAL(ACCTextStickerViewStorageModel*, ACCTextStickerView*, stickerID);
    ACC_SERIALIZATION_KEY_EQUAL(ACCTextStickerViewStorageModel*, ACCTextStickerView*, timeEditingRange);
    
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, x);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, y);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, xRatio);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, yRatio);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, width);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, height);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, rotation);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, scale);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerGeometryModelStorageModel*, ACCStickerGeometryModel*, preferredRatio);
    
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerTimeRangeModelStorageModel*, ACCStickerTimeRangeModel*, pts);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerTimeRangeModelStorageModel*, ACCStickerTimeRangeModel*, startTime);
    ACC_SERIALIZATION_KEY_EQUAL(ACCStickerTimeRangeModelStorageModel*, ACCStickerTimeRangeModel*, endTime);
    
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, typeId);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, hierarchyId);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, minimumScale);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, maximumScale);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, boxPadding);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, boxMargin);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, changeAnchorForRotateAndScale);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, preferredContainerFeature);
    ACC_SERIALIZATION_KEY_EQUAL(ACCCommonStickerConfigStorageModel*, ACCCommonStickerConfig*, gestureInvalidFrameValue);
    
    ACC_SERIALIZATION_KEY_EQUAL(ACCVideoDataClipRangeStorageModel*, IESMMVideoDataClipRange*, startSeconds);
    ACC_SERIALIZATION_KEY_EQUAL(ACCVideoDataClipRangeStorageModel*, IESMMVideoDataClipRange*, durationSeconds);
    ACC_SERIALIZATION_KEY_EQUAL(ACCVideoDataClipRangeStorageModel*, IESMMVideoDataClipRange*, attachSeconds);
    ACC_SERIALIZATION_KEY_EQUAL(ACCVideoDataClipRangeStorageModel*, IESMMVideoDataClipRange*, repeatCount);
    ACC_SERIALIZATION_KEY_EQUAL(ACCVideoDataClipRangeStorageModel*, IESMMVideoDataClipRange*, isDisable);
}

@end

#endif
