//
//  LVEffectPlatformConfig.h
//  LVTemplate
//
//  Created by lxp on 2020/2/19.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN
/// effect面板
typedef NSString* const LVEffectPanelType;
/// - sticker: 贴纸面板
extern LVEffectPanelType LVEffectPanelTypeSticker;
/// - insert: 插入性视频素材
extern LVEffectPanelType LVEffectPanelTypeInsert;
/// - emoji: 贴纸面板表情 (已经废弃)
extern LVEffectPanelType LVEffectPanelTypeEmoji;
/// - emojiNew: 贴纸面板新表情
extern LVEffectPanelType LVEffectPanelTypeEmojiNew;
/// - videoEffect: 视频特效
extern LVEffectPanelType LVEffectPanelTypeVideoEffect;
/// - filter: 滤镜面板
extern LVEffectPanelType LVEffectPanelTypeFilter;
/// - canvas: 画布样式面板
extern LVEffectPanelType LVEffectPanelTypeCanvas;
/// - bubble: 文字气泡面板
extern LVEffectPanelType LVEffectPanelTypeBubble;
/// - flower: 文字花字面板
extern LVEffectPanelType LVEffectPanelTypeFlower;
/// - transitions: 转场面板
extern LVEffectPanelType LVEffectPanelTypeTransitions;
/// - stickerAnimation: 贴纸动画
extern LVEffectPanelType LVEffectPanelTypeStickerAnimation;
/// - textAnimation: 文字动画
extern LVEffectPanelType LVEffectPanelTypeTextAnimation;
/// - videoAnimation: 视频动画
extern LVEffectPanelType LVEffectPanelTypeVideoAnimation;
/// - font：字体
extern LVEffectPanelType LVEffectPanelTypeFont;
/// - system-fonts：系统字体
extern LVEffectPanelType LVEffectPanelTypeSystemFont;
/// - mix: 混合模式
extern LVEffectPanelType LVEffectPanelTypeMix;
/// - curveSpeed: 曲线变速
extern LVEffectPanelType LVEffectPanelTypeCurveSpeed;

extern LVEffectPanelType LVEffectPanelTypeVideoMask;
/// - flower2: 封面设置-文字花字
extern LVEffectPanelType LVEffectPanelTypeCoverFlower;
/// - bubble2: 封面设置-文字气泡
extern LVEffectPanelType LVEffectPanelTypeCoverBubble;
/// - tone: 音色
extern LVEffectPanelType LVEffectPanelTypeTone;
/// - textTemplate: 文字模板
extern LVEffectPanelType LVEffectPanelTypeTextTemplate;
/// - body: 美体
extern LVEffectPanelType LVEffectPanelTypeBody;
/// - beauty2: 人像特效
extern LVEffectPanelType LVEffectPanelTypeFigure;
/// - face-prop: 人脸道具
extern LVEffectPanelType LVEffectPanelTypeFaceEffect;

@interface LVEffectPlatformConfig : NSObject

+ (LVEffectPanelType)panelWithPayloadType:(LVPayloadRealType)payloadType segmentType:(LVPayloadRealType)segmentType categoryID:(NSString *)categoryID categoryName:(NSString *)categoryName;

@end

NS_ASSUME_NONNULL_END
