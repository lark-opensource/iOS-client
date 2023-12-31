//
//  LVDraftAudioEffectPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDefinition.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN


/**
 音频变声效果解析模型
 */
@interface LVDraftAudioEffectPayload (Interface)<LVCopying>

/**
 资源的类型
 */
@property (nonatomic, assign) LVAudioEffectType effectType;

/**
 初始化音频特效
 
 @param type 特效类型
 @return 特效实例
 */
- (instancetype)initWithEffectType:(LVAudioEffectType)type;

@end

NS_ASSUME_NONNULL_END
