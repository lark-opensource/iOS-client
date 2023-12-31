//
//  NLEEffectDrawer.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/6/8.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/IVEEffectProcess.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEEffectDrawer : NSObject

/**
 * @brief 获取视频处理单元
 * @return 特效处理器
 */
- (id<IVEEffectProcess>)getVideoProcess;

// 画笔基础
- (BOOL)brushStart;
- (BOOL)brushEnd;
- (void)removeLastBrush;
- (void)setBrushColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpah:(CGFloat)a;
- (void)setBrushCanvasAlpha:(CGFloat)alpha;
- (void)setBrushSize:(CGFloat)size;
- (NSInteger)currentBrushNumber;

// 画笔手势
- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location;
- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type;
- (BOOL)handleTouchEvent:(CGPoint)location;
- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type;

// 时间特效相关
- (void)setTimeMachineReady:(BOOL)timeMachineReady;
- (BOOL)timeMachineReady;
- (CGFloat)getTimeMachineBegineTime:(HTSPlayerTimeMachineType)type;

- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag;
- (void)appendComposerNodesWithTags:(NSArray<VEComposerInfo *> *)nodes;
// 操作或移除时都可以使用这个接口
- (BOOL)operateComposerNodesWithTags:(NSArray<VEComposerInfo *> *)nodes operation:(IESMMComposerNodesOperation)operation;

@end

NS_ASSUME_NONNULL_END
