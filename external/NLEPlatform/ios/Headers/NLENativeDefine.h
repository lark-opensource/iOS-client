//
//  NLENativeDefine.h
//  Pods
//
//  Created by bytedance on 2020/12/8.
//

#ifndef NLENativeDefine_h
#define NLENativeDefine_h
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NLEError) {
    SUCCESS = 0,
    FAILED = -1,
    OPERATION_ILLEGAL = -2,
    NO_CHANGED = -3,
    OBJECTS_NOT_FOUND = -4,
    NOT_SUPPORT = -5,
    FILE_ACCESS_ERROR = -6,
    PARAM_INVALID = -7
};

typedef NS_ENUM(NSUInteger, NLEResourceTag){
    NLEResourceTagNormal = 0,       // 常规资源 抖音资源
    NLEResourceTagAmazing = 1,      // AMAZING资源 //剪同款资源
};

typedef NS_ENUM(NSUInteger, NLEResourceType){
    NLEResourceTypeNone = 0,                      // 空/无资源/占位节点/无意义
    NLEResourceTypeDraft = 1,                     // 草稿
    NLEResourceTypeVideo = 2,                     // 视频
    NLEResourceTypeAudio = 3,                     // 音频
    NLEResourceTypeImage = 4,                     // 图片
    NLEResourceTypeTransition = 5,                // 转场
    NLEResourceTypeEffect = 6,                    // 特效
    NLEResourceTypeFilter = 7,                    // 滤镜
    NLEResourceTypeSticker = 8,                   // 贴纸
    NLEResourceTypeFlower = 9,                    // 花字
    NLEResourceTypeFont = 10,                     // 字体资源包
    NLEResourceTypeSrt = 11,                      // 歌词字幕 SRT 文件
    NLEResourceTypeAdjust = 12,                   // 调节
    NLEResourceTypeAnimationSticker = 15,         // 贴纸动画资源包
    NLEResourceTypeAnimationVideo = 16,           // 视频动画资源包
    
    NLEResourceTypeMask = 17,                     // 蒙板
    NLEResourceTypePIN = 18,                      // PIN算法文件
    NLEResourceTypeInfoSticker = 19,              // 信息化贴纸资源包
    NLEResourceTypeImageSticker = 20,             // 图片贴纸资源包
    NLEResourceTypeTextSticker = 21,              // 文本贴纸资源包
    NLEResourceTypeSubTitleSticker = 22,          // 歌词字幕贴纸资源包
    NLEResourceTypeEmojiSticker = 23,             // emoji贴纸资源包
    NLEResourceTypeTimeEffect   = 24,             // 内置时间特效
    NLEResourceTypeCherEffect = 25,               // 电音
    NLEResourceTypeChroma = 26,                   // 色度抠图
    NLEResourceTypeAnimationText = 27,            // 文字动画资源包
    NLEResourceTypeLyricSticker = 28,             // 歌词贴纸
    NLEResourceTypeComposer = 29,                 // composer
    NLEResourceTypeAutoSubTitle = 30,             // 自动字幕
    NLEResourceTypeTextTemplate = 31,             // 文字模板资源包
    NLEResourceTypeMixMode = 32,                  // 混合模式
    NLEResourceTypeBubble = 33,                   // 气泡
    NLEResourceTypeTextShape = 34,                // 文字形状
    NLEResourceTypeBeauty = 35,                   // 美颜
    NLEResourceTypeSound = 36,                    // 音效
    NLEResourceTypeRecord = 37,                    // 录音
    NLEResourceTypeAlgorithmMVAudio = 38,         // 算法MV模板音频文件
    NLEResourceTypeMusicMVAudio = 39,              // 动效MV模板音频文件
    NLEResourceTypeNormalMVAudio = 40,             // 普通MV模板音频文件
    NLEResourceTypeVoiceChangerFilter = 41,  ///<变声
    NLEResourceTypeKaraokeUserAudio = 42,          // K歌用户唱的声音资源
    NLEResourceTypeAlgorithmAudio = 43,           // 算法卡点，需要添加一条音轨，该type标识算法卡点音乐资源。Java/OC VE接口不对外暴露创建音轨的过程，使用VE Public Api时需要手动添加音轨。
    NLEResourceTypeAudioDSPFilter = 44,           // 音频DSP滤镜
};

typedef NS_ENUM(NSUInteger, NLECanvasType){
    NLECanvasColor = 0, // 画布类型为颜色
    NLECanvasImage = 1,  // 画布类型为图片
    NLECanvasVideoFrame = 2, // 画布类型为视频帧
    NLECanvasGradientColor = 3, // 画布类型为渐变
};


typedef NS_ENUM(NSUInteger, NLETrackType){
    NLETrackNONE = 0,       // 空/未知/占位
    NLETrackAUDIO = 1,      // 音频
    NLETrackVIDEO = 2,      // 视频
    NLETrackSTICKER = 3,    // 贴纸
    NLETrackEFFECT = 4,     // 特效
    NLETrackFILTER = 5,     // 全局滤镜
    NLETrackImage = 6,      // 图片编辑
    NLETrackMV = 7,         // MV
};

typedef NS_ENUM(NSUInteger, NLEAudioChanger){
    NLEAudioChangerNONE = 0,       // 无
    NLEAudioChangerBOY = 1,      // 男生
    NLEAudioChangerGIRL = 2,      // 女生
    NLEAudioChangerLOLI = 3,    // 萝莉
    NLEAudioChangerUNCLE = 4,     // 大叔
    NLEAudioChangerMONSTER = 5,     // 怪兽
};

typedef NS_ENUM(NSUInteger, NLESegmentTimeEffectType) {
    NLESegmentTimeEffectTypeNormal = 0, // 正常
    NLESegmentTimeEffectTypeRewind = 1, // 倒播
    NLESegmentTimeEffectTypeRepeat = 2, // 重复，业务不指定次数
    NLESegmentTimeEffectTypeSlow   = 3, // 慢播，业务不指定次数
};

typedef NS_ENUM(NSUInteger, NLETempEditorStatus) {
    NLETempEditorEnter = 0,   // 进入临时编辑
    NLETempEditorCancel = 1,  // 取消推出临时编辑
    NLETempEditorSave = 2,    // 保存临时编辑
};

typedef NS_ENUM(NSUInteger, NLEEditorModel) {
    NLEEditorModelDouyin = 0,   // 抖音编辑
    NLEEditorModelCutSame = 1,  // 剪同款编辑
    NLEEditorModelOther = 2,    // MV和影集编辑
};

// MV模板分辨率枚举类
typedef NS_ENUM(NSUInteger, NLESegmentMVResolution) {
    NLESegmentMVResolution720P = 0,
    NLESegmentMVResolution1080P,
};

typedef NS_ENUM(NSUInteger, NLESegmentMVResultInType) {
    NLESegmentMVResultInTypeImage = 0,
    NLESegmentMVResultInTypeVideo = 1,
    NLESegmentMVResultInTypeJson = 2,
};

typedef NS_ENUM(NSUInteger, NLESegmentMVResourceType) {
    NLESegmentMVResourceTypeNone = 0,
    NLESegmentMVResourceTypeImage = 1,
    NLESegmentMVResourceTypeVideo = 2,
    NLESegmentMVResourceTypeAudio = 3,
    NLESegmentMVResourceTypeText = 4,
    NLESegmentMVResourceTypeGif = 5,
    NLESegmentMVResourceTypeBgimg = 6,
    NLESegmentMVResourceTypeRGBA = 7,
};

typedef NS_ENUM(NSUInteger, NLEMediaTransType) {
    NLEMediaTransTypeNone = 0,
    NLEMediaTransTypePath = 1,
    NLEMediaTransTypeZoom = 2,
};

typedef NS_ENUM(NSInteger, NLEDurationMatchType) {
    NLEDurationMatchTypeWrapContent = -1, // 对齐自身的最小/最大值
    NLEDurationMatchTypeMatchParent = -2, // 对齐父节点
};

// MARK: 没有特殊情况不要调整这个mode，抖音场景有的场景不主动设置mode，导致音频时长>视频时长
typedef NS_ENUM(NSUInteger, NLEVideoDurationMode) {
    NLEVideoDurationModeFitToMainTrack, // 以主轨为最长时长【场景:MV】
    NLEVideoDurationModeFillToMaxEnd,   // 填充最长时长【场景:有些剪同款模板最后就是没有视频，只有贴纸，这里拿最长轨道长度】
};

static const int32_t NLERepeatNornal = 1;      //正常
static const int32_t NLERepeatInfinity = -1;   //循环

///这些定义暂时不能删除，抖音已经在用。除非所有依赖仓库升级
typedef NSString *NLEFilterNameOC NS_STRING_ENUM;
static NLEFilterNameOC const COMMON = @"common";
static NLEFilterNameOC const BRIGHTNESS = @"brightness";
static NLEFilterNameOC const CONTRACT = @"contract";
static NLEFilterNameOC const SATURATION = @"saturation";
static NLEFilterNameOC const SHARPEN = @"sharpen";
static NLEFilterNameOC const HIGHLIGHT = @"highlight";
static NLEFilterNameOC const SHADOW = @"shadow";
static NLEFilterNameOC const TEMPERATURE = @"temperature";
static NLEFilterNameOC const TONE = @"tone";
static NLEFilterNameOC const FADE = @"fade";
static NLEFilterNameOC const LIGHT_SENSATION = @"light_sensation";
static NLEFilterNameOC const VIGNETTING = @"vignetting";
static NLEFilterNameOC const PARTICLE = @"particle";
static NLEFilterNameOC const HDR = @"hdr";
static NLEFilterNameOC const LENS_HDR = @"lens_hdr";
static NLEFilterNameOC const VIDEO_LENS_HDR = @"video_lens_hdr";
static NLEFilterNameOC const NLE_AUDIO_COMMON_FILTER = @"audio_common_filter"; ///<音频滤镜/变声

///音频滤镜/LOUDNESS_BALANCE
static NLEFilterNameOC const NLE_AUDIO_LOUDNESS_BALANCE_FILTER = @"audio_loudness_balance_filter";

///音频滤镜/DSP
static NLEFilterNameOC const NLE_AUDIO_DSP_FILTER = @"audio_dsp_filter";

static NLEFilterNameOC const NLE_AUDIO_VOLUME_FILTER = @"audio_volume_filter";

static NLEFilterNameOC const AI_MATTING = @"ai_matting";

/// 对齐模式
typedef NSString *NLEAlignModeOC NS_STRING_ENUM;
static NLEAlignModeOC const ALIGN_CANVAS = @"align_canvas";
static NLEAlignModeOC const ALIGN_VIDEO = @"align_video";

#endif /* NLENativeDefine_h */
