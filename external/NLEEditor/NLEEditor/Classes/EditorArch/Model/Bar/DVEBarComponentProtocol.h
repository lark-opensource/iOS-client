//
//   DVEBarComponentProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>

///节点类型对象
typedef NS_ENUM(NSInteger, DVEBarComponentType) {
    DVEBarComponentTypeRoot = 100,     ///根节点,起始值必须大于0
    DVEBarComponentTypeCut,          ///剪辑
    DVEBarComponentTypeBlendCut,          ///副轨剪辑
    DVEBarComponentTypeCanvas,       ///画布
    DVEBarComponentTypeAudio,        ///音频
    DVEBarComponentTypeSticker,      ///贴纸
    DVEBarComponentTypeText,         ///文本
    DVEBarComponentTypeFilterPartly,       ///局部滤镜
    DVEBarComponentTypeFilterGobal,       ///全局滤镜
    DVEBarComponentTypeRegulate,     ///调节
    DVEBarComponentTypePicInPic,     ///画中画
    DVEBarComponentTypeEffect,      ///特效
    DVEBarComponentTypeEffectSubReplace, ///替换特效
    DVEBarComponentTypeEffectSubObject, ///特效作用对象
    DVEBarComponentTypeSplit,        ///拆分
    DVEBarComponentTypeSpeed,        ///速度
    DVEBarComponentTypeRotate,       ///旋转
    DVEBarComponentTypeFlip,         ///翻转
    DVEBarComponentTypeCrop,         ///裁剪
    DVEBarComponentTypeReverse,      ///倒放
    DVEBarComponentTypeSound,        ///音量
    DVEBarComponentTypeAnimation,    ///动画
    DVEBarComponentTypeAnimationIn,         ///进场动画
    DVEBarComponentTypeAnimationOut,        ///出场动画
    DVEBarComponentTypeAnimationCombine,    ///组合动画
    DVEBarComponentTypeTransitionAnimation,    ///转场动画
    DVEBarComponentTypeMask,         ///蒙版
    DVEBarComponentTypeMixedMode,    ///混合模式
    DVEBarComponentTypeTextRecognize,///语音转字幕
    DVEBarComponentTypeTextReader, ///文本朗读
    DVEBarComponentTypeCanvasBackground,    ///背景画布
    DVEBarComponentTypeCanvasBackgroundColor,         ///画布颜色
    DVEBarComponentTypeCanvasBackgroundStyle,         ///画布样式
    DVEBarComponentTypeCanvasBackgroundBlur,         ///画布模糊
    DVEBarComponentTypeFreeze,         ///定格
    DVEBarComponentTypeNormalSpeed,         ///常规变速
    DVEBarComponentTypeVideoCover,    ///视频封面
    /// 文字模板
    DVEBarComponentTypeTextTemplate,
    ////基础节点类型
    DVEBarComponentTypeBack,          ///一级返回
    DVEBarComponentTypeBack2,          ///二级返回
    ///建议增\删\改\复制等常规操作可以当作Action类型
    DVEBarComponentTypeAction,       ///动作
    ///自定义节点类型分割值，业务方知定义类型必须在此基础上累加
    DVEBarComponentTypeCustomMinValue
};

//子节点状态
typedef NS_ENUM(NSInteger, DVEBarSubComponentGroup) {
    DVEBarSubComponentGroupAdd = 0,
    DVEBarSubComponentGroupEdit  = 1,
};

///节点入口状态
typedef NS_ENUM(NSInteger, DVEBarComponentViewStatus) {
    DVEBarComponentViewStatusNormal = 0,    //正常展示
    DVEBarComponentViewStatusHidden  = 1,   //隐藏
    DVEBarComponentViewStatusDisable = 2    //置灰不可点击
};

@protocol DVEBarComponentViewModelProtocol <NSObject>
///节点标题
@property (nonatomic, copy) NSString *title;
///节点icon地址
///优先使用
@property (nonatomic, strong) NSURL *imageURL;
///节点icon
///当imageURL为nil ，则使用localAssetImage
@property (nonatomic, strong) UIImage *localAssetImage;

@end

@protocol DVECommonBarComponentProtocol <NSObject>

/// 当前节点类型
@property (nonatomic, assign) DVEBarComponentType componentType;
/// 节点视图模型
@property (nonatomic, strong) id<DVEBarComponentViewModelProtocol> viewModel;

@end

@protocol DVEBarComponentProtocol <DVECommonBarComponentProtocol>

///父节点
@property (nonatomic, weak) id<DVEBarComponentProtocol> parent;
///当前节点分组
@property (nonatomic, assign) DVEBarSubComponentGroup componentGroup;
///下级节点数组
@property (nonatomic, copy) NSArray<id<DVEBarComponentProtocol>> *subComponents;
///当前子节点展示的分组
@property (nonatomic, assign) DVEBarSubComponentGroup currentSubGroup;
///获取节点状态action的名称
///执行的action必须是DVEComponentActionManager对象下的方法
@property (nonatomic, copy) NSString *statusActionName;
///action名称
///执行的action必须是DVEComponentActionManager对象下的方法
@property (nonatomic, copy) NSString *clickActionName;

@end
