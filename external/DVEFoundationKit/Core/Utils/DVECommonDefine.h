//
//  DVECommonDefine.h
//  DVEFoundationKit
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DVEPlayerStatus) {
    /// 空闲状态, seek的时候也会处于这个状态
    DVEPlayerStatusIdle,
    /// 等待播放
    DVEPlayerStatusWaitingPlay,
    /// 播放中
    DVEPlayerStatusPlaying,
    /// 等待处理（请勿进行操作）
    DVEPlayerStatusWaitingProcess,
    /// 处理中或未准备好（请勿进行操作）
    DVEPlayerStatusProcessing,
};

typedef NS_ENUM(NSInteger, DVEModuleTypeBackgroundSubType) {
    DVEModuleTypeBackgroundSubTypeCanvasColor = 0,
    DVEModuleTypeBackgroundSubTypeCanvasStyle = 1,
    DVEModuleTypeBackgroundSubTypeCanvasBlur  = 2,
};

typedef NS_ENUM(NSUInteger,DVECanvasRatio){
    DVECanvasRatioOriginal,
    DVECanvasRatio9_16,
    DVECanvasRatio3_4,
    DVECanvasRatio1_1,
    DVECanvasRatio4_3,
    DVECanvasRatio16_9,
    DVECanvasRatioFromModel,
};

/**
 导出分辨率
 */
typedef NS_ENUM(NSInteger, DVEExportResolution) {
    DVEExportResolutionP540 = 540,
    DVEExportResolutionP720 = 720,
    DVEExportResolutionP1080 = 1080,
    DVEExportResolutionP4K = 2160
};

/**
 导出帧率
 */
typedef NS_ENUM(NSInteger, DVEExportFPS) {
    DVEExportFPS24 = 24,
    DVEExportFPS25 = 25,
    DVEExportFPS30 = 30,
    DVEExportFPS50 = 50,
    DVEExportFPS60 = 60
};

/// 文本-设置区-颜色
typedef NS_ENUM(NSUInteger, DVETextColorConfigType) {
    DVETextColorConfigTypeFont,
    /// 描边
    DVETextColorConfigTypeOutline,
    /// 底色
    DVETextColorConfigTypeBackground,
    DVETextColorConfigTypeShadow,
    /// 排列
    DVETextColorConfigTypeArrange,
    /// 粗斜体
    DVETextColorConfigTypeBlod
};

typedef NS_ENUM(NSUInteger, DVEBusinessType) {
    DVEBusinessTypeEdit, // 多轨编辑
    DVEBusinessTypeTemplate, // 基于多轨编辑的模板编辑
    DVEBusinessTypeEditLite, // 轻剪辑
};

typedef NS_ENUM(NSInteger, DVEPreviewEditType) {
    DVEPreviewEditTypeNone,
    DVEPreviewEditTypeCanvas,
    DVEPreviewEditTypeEditBox,//贴纸，文本和文字模版都属于编辑框类型
    DVEPreviewEditTypeMask,
};


NS_ASSUME_NONNULL_END
