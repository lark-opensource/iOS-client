//
//  LVDraftAudioFadePayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频淡入淡出素材解析模型
 */
//@interface LVDraftAudioFadePayload : LVDraftPayload
@interface LVDraftAudioFadePayload (Interface)
/**
 进入时长
 */
@property (nonatomic, assign) float fadeInDuration;

/**
 退出时长
 */
@property (nonatomic, assign) float fadeOutDuration;

/**
 淡入偏移【目前只用于拍摄预览，不存草稿】：比如淡入在2s内从0增加到100dB，偏移量就是指：淡入只用50dB ~ 100dB这一段，那么1s就是这个偏移量
 */
@property (nonatomic, assign) CGFloat fadeIndeOffset;

/**
 初始化淡入淡出实例
 
 @param fadeInDuration 淡入时长
 @param fadeOutDuration 淡出时长
 @return 淡入淡出实例
 */
- (instancetype)initWithFadeInDuration:(float)fadeInDuration fadeOutDuration:(float)fadeOutDuration;

@end

NS_ASSUME_NONNULL_END
