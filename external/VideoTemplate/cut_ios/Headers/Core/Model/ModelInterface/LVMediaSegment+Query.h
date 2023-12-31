//
//  LVMediaSegment+Query.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/12.
//
#import "LVMediaSegment.h"
#import <AVFoundation/AVFoundation.h>
#import "LVMediaAsset.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaSegment (Query)

- (nullable AVAsset *)videoAsset;
- (nullable LVMediaAsset *)mediaAsset;
- (nullable NSURL *)imageAssetFileURL;

- (nullable LVMediaAsset *)aiMattingAsset;
- (BOOL)isAppliedAIMatting;
- (void)applyAIMatting:(BOOL)isAIMatting;

- (BOOL)isAIMattingMaskEnableFunction;
- (BOOL)isAIMattingMaskApplyEffect;
- (void)setAIMattingMaskApplyEffect:(BOOL)aiMattingMaskApplyEffect;

- (CGFloat)actualVolume;

@end

NS_ASSUME_NONNULL_END
