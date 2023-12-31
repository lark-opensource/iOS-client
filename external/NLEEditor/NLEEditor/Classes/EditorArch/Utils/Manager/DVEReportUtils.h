//
//  DVEReportUtil.h
//  NLEEditor
//
//  Created by bytedance on 2021/7/14.
//

#import <Foundation/Foundation.h>
#import "DVEBarComponentProtocol.h"
#import "DVEVCContext.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXTERN NSString * const DVEVideoEditToolsClick;
FOUNDATION_EXTERN NSString * const DVEVideoEditToolsCutClick;

typedef NS_ENUM(NSInteger, DVEBarActionType) {
    DVEBarActionTypeRoot = DVEBarComponentTypeRoot,     ///根节点,起始值必须大于0
    DVEBarActionTypeCut = DVEBarComponentTypeCut,          ///剪辑
    DVEBarActionTypeBlendCut = DVEBarComponentTypeBlendCut,          ///副轨剪辑
    DVEBarActionTypeCanvas = DVEBarComponentTypeCanvas,       ///画布（比例）
    DVEBarActionTypeAudio = DVEBarComponentTypeAudio,        ///音频
    DVEBarActionTypeSticker = DVEBarComponentTypeSticker,      ///贴纸
    DVEBarActionTypeText = DVEBarComponentTypeText,         ///文本
    DVEBarActionTypeFilterPartly = DVEBarComponentTypeFilterPartly,       ///局部滤镜
    DVEBarActionTypeFilterGlobal = DVEBarComponentTypeFilterGobal,       ///全局滤镜
    DVEBarActionTypeRegulate = DVEBarComponentTypeRegulate,     ///调节
    DVEBarActionTypePicInPic = DVEBarComponentTypePicInPic,     ///画中画
    DVEBarActionTypeEffectGlobal = DVEBarComponentTypeEffect,      ///特效
//    DVEBarActionTypeEffectSubReplace = DVEBarComponentTypeEffectSubReplace, ///替换特效（暂时废弃）
//    DVEBarActionTypeEffectSubObject = DVEBarComponentTypeEffectSubObject, ///特效作用对象
    DVEBarActionTypeSplit = DVEBarComponentTypeSplit,        ///拆分
    DVEBarActionTypeSpeed = DVEBarComponentTypeSpeed,        ///速度
    DVEBarActionTypeRotate = DVEBarComponentTypeRotate,       ///旋转
    DVEBarActionTypeFlip = DVEBarComponentTypeFlip,         ///翻转
    DVEBarActionTypeCrop = DVEBarComponentTypeCrop,         ///裁剪
    DVEBarActionTypeReverse = DVEBarComponentTypeReverse,      ///倒放
    DVEBarActionTypeSound = DVEBarComponentTypeSound,        ///音量
    DVEBarActionTypeAnimation = DVEBarComponentTypeAnimation,    ///动画
    DVEBarActionTypeAnimationIn = DVEBarComponentTypeAnimationIn,         ///进场动画
    DVEBarActionTypeAnimationOut = DVEBarComponentTypeAnimationOut,        ///出场动画
    DVEBarActionTypeAnimationCombine = DVEBarComponentTypeAnimationCombine,    ///组合动画
    DVEBarActionTypeTransitionAnimation = DVEBarComponentTypeTransitionAnimation,    ///转场动画
    DVEBarActionTypeMask = DVEBarComponentTypeMask,         ///蒙版
    DVEBarActionTypeMixedMode = DVEBarComponentTypeMixedMode,    ///混合模式
    DVEBarActionTypeTextRecognize = DVEBarComponentTypeTextRecognize,///语音转字幕
    DVEBarActionTypeTextReader = DVEBarComponentTypeTextReader, ///文本朗读
//    DVEBarActionTypeCanvasBackground = DVEBarComponentTypeCanvasBackground,    ///背景画布
//    DVEBarActionTypeCanvasBackgroundColor = DVEBarComponentTypeCanvasBackgroundColor,         ///画布颜色
//    DVEBarActionTypeCanvasBackgroundStyle = DVEBarComponentTypeCanvasBackgroundStyle,         ///画布样式
//    DVEBarActionTypeCanvasBackgroundBlur = DVEBarComponentTypeCanvasBackgroundBlur,         ///画布模糊
    DVEBarActionTypeFreeze = DVEBarComponentTypeFreeze,         ///定格
    DVEBarActionTypeNormalSpeed = DVEBarComponentTypeNormalSpeed,         ///常规变速
    ////基础节点类型
//    DVEBarActionTypeBack = DVEBarComponentTypeBack,          ///返回
    ///建议增\删\改\复制等常规操作可以当作Action类型
    DVEBarActionTypeAction = DVEBarComponentTypeAction,       ///动作
    ///自定义节点类型分割值，业务方知定义类型必须在此基础上累加
//    DVEBarActionTypeCustomMinValue = DVEBarComponentTypeCustomMinValue,
    DVEBarActionTypeAudioAdd,  ///添加音频
    DVEBarActionTypeAudioRecord,  ///录音
    DVEBarActionTypeStickerAdd,  ///添加贴纸
    DVEBarActionTypeTextAdd,  ///添加文字
    DVEBarActionTypeFilterAdd,  ///添加滤镜
    DVEBarActionTypeEffectAdd,  ///添加特效
    DVEBarActionTypePicInPicAdd,  ///添加画中画
    DVEBarActionTypeEffectReplace,  ///替换特效
    DVEBarActionTypeEffectCopy,   ///复制特效
    DVEBarActionTypeEffectDelete,   ///删除特效
    DVEBarActionTypeAudioSound,  ///音频音量
    DVEBarActionTypeAudioDelete,   ///音频删除
    DVEBarActionTypeTextEdit,   ///编辑文本
    DVEBarActionTypeTextDelete,   ///删除文本
};

@interface DVEReportUtils : NSObject

+ (instancetype)reportUtilWithVCConext:(DVEVCContext *)vcContext;
+ (void)logComponentClickAction:(DVEVCContext *)vcContext event:(NSString *)event actionType:(DVEBarActionType)type;
+ (void)logComponentClick:(DVEVCContext *)vcContext currentComponent:(id<DVEBarComponentProtocol>)currentComponent clickComponent:(id<DVEBarComponentProtocol>)clickComponent;
+ (void)logVideoExportClickEvent:(DVEVCContext *)vcContext;
+ (void)logVideoExportResultEvent:(DVEVCContext *)vcContext isSuccess:(BOOL)isSuccess failCode:(NSString * _Nullable)failCode failMsg:(NSString * _Nullable)failMsg;

+ (void)logEvent:(NSString *)serviceName params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
