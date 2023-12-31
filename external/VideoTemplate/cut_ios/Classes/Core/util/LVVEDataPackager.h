//
//  IESLVPlayerDataPackager.h
//  cut_ios
//
//  Created by wangchengyi on 2019/12/6.
//  Copyright © 2019 zhangyeqi. All rights reserved.
//

#ifndef IESLVPlayerDataPackager_h
#define IESLVPlayerDataPackager_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <TTVideoEditor/IESMMAudioEffectConfig.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>
#import <TTVideoEditor/HTSTransformFilter.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <TTVideoEditor/HTSDefine.h>
#include <TemplateConsumer/Materials.h>
#include <TemplateConsumer/Clip.h>
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/MaterialCanvas.h>
#include <TemplateConsumer/MaterialAudioFade.h>
#include <cut/param/filter/LVVECanvasFilterParam.h>
#import "ComVEEditor.h"

static NSString * _Nonnull RATIO_ORIGINAL = @"original";
static NSString * _Nonnull RATIO_3_4 = @"3:4";
static NSString * _Nonnull RATIO_1_1 = @"1:1";
static NSString * _Nonnull RATIO_9_16 = @"9:16";
static NSString * _Nonnull RATIO_4_3 = @"4:3";
static NSString * _Nonnull RATIO_16_9 = @"16:9";

NS_ASSUME_NONNULL_BEGIN

@interface LVVEDataPackager : NSObject

//+ (NSDictionary *)scaleCanvasAspect:(CGRect)inRect canvasFilterParam:(cut::LVVECanvasFilterParam)canvasFilterParam;

+ (nullable IESMMAudioPitchConfig *)pitchConfigWithVoiceName:(NSString *)voiceName videoEffectPath:(NSString *)path;

+ (IESMMCanvasConfig *)canvasConfigForCanvasMaterial:(std::shared_ptr<CutSame::MaterialCanvas>)materialCanvas rootPath:(NSString *)rootPath;

+ (TransformTextureVertices *)verticesForCrop:(CutSame::Crop)crop;

+ (void)updateCanvasSource:(IESMMCanvasSource *)source fromClip:(CutSame::Clip)clip cropScale:(float)cropScale;

+ (NSString *_Nullable)filePathInProjec:(std::shared_ptr<CutSame::TemplateModel>)project relativePath:(std::string)relativePath;

+ (IESMMAudioFadeConfig *_Nullable)fadeConfigOfSegment:(std::shared_ptr<CutSame::MaterialAudioFade>)fadeMaterial targetDuration:(NSTimeInterval)targetDuration;

+ (cut::ComVEState)comStateWithVEStatus:(HTSPlayerStatus)veState;

+ (HTSPlayerStatus)vePlayerStatusWithInt:(NSInteger)intValue;

@end

NS_ASSUME_NONNULL_END

#endif /* IESLVPlayerDataPackager_h */
