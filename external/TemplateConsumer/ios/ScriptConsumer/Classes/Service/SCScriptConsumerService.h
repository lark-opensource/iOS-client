//
//   SCScriptConsumerService.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/31.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLEResourceNode+iOS.h>
#import <NLEPlatform/NLETrackSlot+iOS.h>
#import <NLEPlatform/NLESegment+iOS.h>
#import "SCScriptModel+iOS.h"
#import "SCScriptConsumer+iOS.h"
#import "SCScriptConsumerConstant.h"
#import <NLEPlatform/NLENativeDefine.h>
#import <NLEPlatform/NLESegmentTransition+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCScriptConsumerService : NSObject


/// ScriptModel转换NLEModel
/// @param script SCScriptModel_OC
/// @param adjustHandler 转换NLEModel后，所有Slot回调
/// @param sortHandler 单个场景调整中，每个视频Slot回调
+(NLEModel_OC*)convertNLEModelWithScriptModel:(SCScriptModel_OC*)script adjustHandler:(SCScriptConsumerAdjuectHandler __nullable)adjustHandler
    sortHandler:(SCScriptConsumerSortSlotHandler __nullable)sortHandler;


/// ScriptModel转换NLEModel
/// @param script SCScriptModel_OC
+(NLEModel_OC*)convertNLEModelWithScriptModel:(SCScriptModel_OC*)script;


/// 获取音频类型本地资源Segment
/// @param model nleModel
+(NSArray<NLESegmentAudio_OC*>*)audioSegmentsInModel:(NLEModel_OC*)model;

/// 获取视频类型本地资源Segment
/// @param model nleModel
+(NSArray<NLESegmentVideo_OC*>*)videoSegmentsInModel:(NLEModel_OC*)model;


/// 获取所有本地资源Segment
/// @param model nleModel
+(NSArray<NLESegment_OC*>*)segmentsInModel:(NLEModel_OC*)model;


/// 判断是否本地资源
/// @param node NLEResourceNode
+(BOOL)isMutableResNode:(NLEResourceNode_OC*)node;

/// 判断是否本地资源
/// @param slot NLETrackSlot
+(BOOL)isMutableNLESlot:(NLETrackSlot_OC*)slot;


/// 判断是否本地资源
/// @param segment NLESegment_OC
+(BOOL)isMutableSegment:(NLESegment_OC*)segment;


/// 通过字幕对象生成NLETrack
/// @param subTitles 字幕列表
+(NLETrack_OC*)geneStickerTrack:(NSArray<SCSubTitle_OC*>*)subTitles;

/// 获取所有转场segment以及对应索引值
/// @param model nleModel
+(NSDictionary<NSString*,NLESegmentTransition_OC*>*)allIndexTransition:(NLEModel_OC*)model;

/// 重制所有转场
/// @param transitions 转场segment以及对应索引值
/// @param model nleModel
+(void)resetAllIndexTransition:(NSDictionary<NSString*,NLESegmentTransition_OC*>*)transitions model:(NLEModel_OC*)model;


/// 构造NLESegmentTransition_OC
/// @param path 资源路径
/// @param duration 时长
/// @param overlay 是否跨视频
+(NLESegmentTransition_OC*)createTransitionSegment:(NSString*)path duration:(CMTime)duration overlay:(BOOL)overlay resourceId:(NSString*)resourceId;


/// NLE的X坐标转VE的X坐标
/// @param nleX  x坐标
+(CGFloat)nleXtoVeX:(CGFloat)nleX;

/// NLE的Y坐标转VE的Y坐标
/// @param nleY  y坐标
+(CGFloat)nleYtoVeY:(CGFloat)nleY;

/// VE的X坐标转NLE的X坐标
/// @param veX  x坐标
+(CGFloat)veXtoNleX:(CGFloat)veX;

/// VE的Y坐标转NLE的Y坐标
/// @param veY  y坐标
+(CGFloat)veYtoNleY:(CGFloat)veY;
@end

NS_ASSUME_NONNULL_END
