//
//  LVMediaDefinition.h
//  longVideo
//
//  Created by zenglifeng on 2019/7/17.
//

#ifndef LVMediaDefinition_h
#define LVMediaDefinition_h

#define LV_SafeGet(type, name, default) - (type *)name { if (!_##name) { _##name = default; } return _##name; }

#define LV_SafeStringProperty(name) LV_SafeGet(NSString, name, @"")

// 重命名
#define LV_ReName_Property(type, NewName, newName, oldName) \
- (type)newName { \
return self.oldName; \
} \
\
- (void)set##NewName:(type)newName \
{\
self.oldName = newName;\
}

// 快速添加一个属性，并且重命名
#define LV_category_property(__type, __name) \
property (nonatomic, strong) __type* __name;

// 对一个分类的属性实现关联方法
#define LV_category_property_Imp(__type, __Name, __name) \
- (__type *)__name { \
  __type *value = objc_getAssociatedObject(self, #__name);\
  if (!value) { \
     value = [[__type alloc] init];\
     self.__name = value; \
  } \
  return value; \
}\
\
- (void)set##__Name:(__type *)__##__name { \
  objc_setAssociatedObject(self, #__name, __##__name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
}

// 给一个现有类添加一个分类（Package），分类上添加一个属性，并实现方法
#define LV_category_AddTo(TargetClass, propertyClass, PropertyName, propertyName) \
@interface TargetClass (Package) \
@LV_category_property(propertyClass, propertyName) \
@end \
\
@implementation TargetClass (Package) \
LV_category_property_Imp(propertyClass, PropertyName, propertyName) \
@end

//https://stackoverflow.com/questions/17132017/how-do-i-write-a-recursive-for-loop-repeat-macro-to-generate-c-code-with-the-c
//#define LV_SafeStringList(args...) TODO: 一个可变参数列表的宏定义，直接展开


/**
 轨道类型
 
 - LVMediaTrackTypeVideo: 视频
 - LVMediaTrackTypeAudio: 音频
 - LVMediaTrackTypeSticker: 贴纸
 - LVMediaTrackTypeVideoEffect: 视频特效
 - LVMediaTrackTypeFilter: 全局滤镜&调节
 - LVMediaTrackTypeArticleVideo: 文字转视频的混合轨道
 */
typedef NS_ENUM(NSUInteger, LVMediaTrackType) {
    LVMediaTrackTypeVideo = 0,
    LVMediaTrackTypeAudio,
    LVMediaTrackTypeSticker,
    LVMediaTrackTypeVideoEffect,
    LVMediaTrackTypeFilter,
    LVMediaTrackTypeArticleVideo,
};

/**
 轨道类型扩展
 - LVMediaTrackFlagNormal: 普通轨道
 - LVMediaTrackFlagSubTile: 字幕轨道
 - LVMediaTrackFlagSubVideo：画中画轨道
 - LVMediaTrackFlagSubTitleVideoAudio：视频原声字幕轨
 - LVMediaTrackFlagSubTitleRecording：录音字幕轨
 */
typedef NS_ENUM(NSUInteger, LVMediaTrackFlag) {
    LVMediaTrackFlagNormal = 0,
    LVMediaTrackFlagSubTitle = 1,
    LVMediaTrackFlagSubVideo = 2,
    LVMediaTrackFlagLyrics   = 3,
    LVMediaTrackFlagSubTitleVideoAudio   = 4,
    LVMediaTrackFlagSubTitleRecording   = 5,
};

typedef NS_ENUM(NSUInteger, LVCanvasRatio) {
    LVCanvasRatio_Original,
    LVCanvasRatio_r16_9,
    LVCanvasRatio_r9_16,
    LVCanvasRatio_r4_3,
    LVCanvasRatio_r3_4,
    LVCanvasRatio_r1_1,
    LVCanvasRatio_r2_1,
    LVCanvasRatio_r235_100,
    LVCanvasRatio_r185_100,
    LVCanvasRatio_r1125_2436,
};

typedef NS_ENUM(NSUInteger, LVTransitionType) {
    LVTransitionTypeNone = 0,
    LVTransitionTypeWhite,
    LVTransitionTypeBlack,
    LVTransitionTypeLeft,
    LVTransitionTypeRight,
    LVTransitionTypeCross,
    LVTransitionTypeZoomin,
    LVTransitionTypeZoomout,
    LVTransitionTypeVerticalLine,
    LVTransitionTypeHorizontalLine,
    LVTransitionTypeCircleMask,
    LVTransitionTypeDissolve,
    LVTransitionTypeMoveUp,
    LVTransitionTypeMoveDown,
    LVTransitionTypeUp,
    LVTransitionTypeDown,
    LVTransitionTypePath
};

typedef NS_ENUM(NSUInteger, LVAudioEffectType) {
    LVAudioEffectTypeNone = 0,
    LVAudioEffectTypeUncle,
    LVAudioEffectTypeLoli,
    LVAudioEffectTypeGirl,
    LVAudioEffectTypeBoy,
    LVAudioEffectTypeMonster
};

/**
 导出分辨率
 */
typedef NS_ENUM(NSInteger, LVExportResolution) {
    LVExportResolutionP480 = 480,
    LVExportResolutionP720 = 720,
    LVExportResolutionP1080 = 1080,
    LVExportResolutionP2K = 1440,
    LVExportResolutionP4K = 2160
};

/**
 导出帧率
 */
typedef NS_ENUM(NSInteger, LVExportFPS) {
    LVExportFPSF24 = 24,
    LVExportFPSF25 = 25,
    LVExportFPSF30 = 30,
    LVExportFPSF50 = 50,
    LVExportFPSF60 = 60
};

/**
 视频片段的附加的类型
 HasSeparatedAudio    已经分离音频
 */
typedef NS_ENUM(NSUInteger, LVVideoResourceExtraTypeOption) {
    LVVideoResourceExtraTypeOptionOriginal = 0,
    LVVideoResourceExtraTypeOptionHasSeparatedAudio = 1 << 0,
};

/**
素材的裁剪比例
*/
//typedef NS_ENUM(NSUInteger, LVVideoCropRatio) {
//    LVVideoCropRatio_Free,
//    LVVideoCropRatio_r16_9,
//    LVVideoCropRatio_r9_16,
//    LVVideoCropRatio_r4_3,
//    LVVideoCropRatio_r3_4,
//    LVVideoCropRatio_r1_1,
//};

#if defined(__cplusplus)
    extern "C" {
#endif /* defined(__cplusplus) */
    NSArray<NSString *>* _Nullable audioEffectNameArray(void);
#if defined(__cplusplus)
    }
#endif /* defined(__cplusplus) */

@protocol LVCopying <NSCopying>
/**
 拷贝实例(ID不拷贝)
 @return 实例
 */
@optional
- (nonnull instancetype)copyToAnother;

/**
 拷贝实例(外部传入资源ID)
 
 @param payloadID 传入ID
 @return 实例
 */
@optional
- (nonnull instancetype)copyToAnotherWithID:(nonnull NSString *)ID;

/**
 拷贝实例
 */
- (nonnull instancetype)copy;

@end
#endif /* LVMediaDefinition_h */
