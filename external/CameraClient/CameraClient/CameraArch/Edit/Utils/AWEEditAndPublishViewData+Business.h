//
//  AWEEditAndPublishViewData+Business.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2021/3/30.
//

#import <CreativeKit/AWEEditAndPublishViewData.h>

NS_ASSUME_NONNULL_BEGIN

// 以下顺序根据优先级排序，None比较特殊，排序时放到前面还是后面根据需求界定
typedef NS_ENUM(NSUInteger, AWEEditAndPublishViewDataType) {
    AWEEditAndPublishViewDataTypeNone = 0, ///< 未定义
    AWEEditAndPublishViewDataTypeRedpacket, ///< 红包
    AWEEditAndPublishViewDataTypeNewYearWish, /// 新年心愿
    AWEEditAndPublishViewDataTypeQuickSave, ///<快速保存: 存草稿 | 存私密 | 存本地
    AWEEditAndPublishViewDataTypeSelectMusic, ///< 选音乐 或者 选配乐，两者不会同时出现
    AWEEditAndPublishViewDataTypeImageVideoSwitch, ///<图集发布模式下 切换到视频/图片编辑模式 两者不会同时出现
    AWEEditAndPublishViewDataTypeEffect, ///< 特效
    AWEEditAndPublishViewDataTypeKaraoke, ///< K歌
    AWEEditAndPublishViewDataTypeText, ///< 文字
    AWEEditAndPublishViewDataTypeSticker, ///< 贴纸
    AWEEditAndPublishViewDataTypeCrop, ///< 图片裁切
    AWEEditAndPublishViewDataTypeTags, ///< 标记
    AWEEditAndPublishViewDataTypeVoiceChange, ///< 变声
    AWEEditAndPublishViewDataTypeFilter, ///< 滤镜
    AWEEditAndPublishViewDataTypeDub, ///< 配音
    AWEEditAndPublishViewDataTypeVolume, ///< 音量
    AWEEditAndPublishViewDataTypeCutMusic, ///< 剪音乐
    AWEEditAndPublishViewDataTypeRotateAndCrop, ///< 旋转裁剪
    AWEEditAndPublishViewDataTypeEmotion, ///< 表情
    AWEEditAndPublishViewDataTypeChangeBGM, ///< 更换配乐
    AWEEditAndPublishViewDataTypeSwitchDirection, ///< 照片电影左右切换
    AWEEditAndPublishViewDataTypeSelectCover, ///< 选择封面
    AWEEditAndPublishViewDataTypeVideoEnhance, ///< 画质增强
    AWEEditAndPublishViewDataTypeStatusBgImage, ///< status选择背景
    AWEEditAndPublishViewDataTypeVideoClip, ///<剪视频
    AWEEditAndPublishViewDataTypeSelectTemplate, ///<选模板
    AWEEditAndPublishViewDataTypeVideoAutoCaption, ///<Auto caption
    AWEEditAndPublishViewDataTypeLocation, /// publish / select location
    AWEEditAndPublishViewDataTypePrivacy, /// publish / change privacy
    AWEEditAndPublishViewDataTypeMoreActions, /// publish / more
    AWEEditAndPublishViewDataTypeSaveDraft, /// publish / save draft
    
    AWEEditAndPublishViewDataTypeClipSwitch,    /// clip / switch on/off
    AWEEditAndPublishViewDataTypeClipAI,        /// clip / ai
    AWEEditAndPublishViewDataTypeClipRange,     /// clip / range
    AWEEditAndPublishViewDataTypeRotate,    /// clip / rotate
    AWEEditAndPublishViewDataTypeSpeed,     /// clip / speed
    AWEEditAndPublishViewDataTypeDelete,    /// clip / delete
    AWEEditAndPublishViewDataTypeReshoot,   /// clip / reshoot
    AWEEditAndPublishViewDataTypeMeteorMode,
    
    AWEEditAndPublishViewDataTypeSmartMovie,
};

@interface AWEEditAndPublishViewData (Business)

@property (nonatomic, assign) AWEEditAndPublishViewDataType type;

@end

NS_ASSUME_NONNULL_END
