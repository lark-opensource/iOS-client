//
//  ACCEditEffectProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/9/8.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditEffectProtocol <ACCEditWrapper>

@property (nonatomic, assign) BOOL timeMachineReady;

- (id<IVEEffectProcess> _Nonnull)getVideoProcess;
- (void)removeAllEffect;
- (void)clearReverseAsset;
- (void)setEffectPathBlock:(effectPathBlock _Nonnull)block;
- (void)applyTimeMachineWithConfig:(IESMMTimeMachineConfig *_Nonnull)timeMachineConfig;
- (void)setBrushCanvasAlpha:(CGFloat)alpha;
- (void)restartReverseAsset:(VEReverseCompleteBlock _Nonnull)complete;
- (void)setEffectLoadStatusBlock:(IESStickerStatusBlock _Nonnull)stickerStatusBlock;
- (void)stopEffectwithTime:(CGFloat)stopTime;
- (CGFloat)removeEffectWithRangeID:(NSString *_Nonnull)rangeID;
- (CGFloat)getTimeMachineBegineTime:(HTSPlayerTimeMachineType)type;
- (NSInteger)currentBrushNumber;
- (void)startEffectWithPathId:(NSString *_Nonnull)pathId withTime:(CGFloat)startTime;
- (void)setEffectWidthPathID:(NSString *)pathID withStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime;
- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag;

- (BOOL)brushStart;
- (BOOL)brushEnd;
- (void)setBrushSize:(CGFloat)size;
- (void)setBrushColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpah:(CGFloat)a;
- (void)removeLastBrush;

- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type;
- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type;
- (BOOL)handleTouchEvent:(CGPoint)location;
- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location;

// Transition composer
- (void)removeComposerNodes;

@optional
- (effectPathBlock)effectPathBlock;

@end

NS_ASSUME_NONNULL_END
