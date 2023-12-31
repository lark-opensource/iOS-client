//
//   DVEResourceModel.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/14.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DVEResourceModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DVEAnimationType) {
    DVEAnimationTypeIn      = 0,
    DVEAnimationTypeOut     = 1,
    DVEAnimationTypeLoop    = 2,
};

typedef NS_ENUM(NSInteger, DVEModuleCanvasType) {
    DVEModuleCanvasTypeOriginal = 0,
    DVEModuleCanvasType9_16,
    DVEModuleCanvasType3_4,
    DVEModuleCanvasType1_1,
    DVEModuleCanvasType4_3,
    DVEModuleCanvasType16_9,
   
};


typedef NS_ENUM(NSUInteger, DVEResourceModelStatus) {
    DVEResourceModelStatusDefault           = 0, // 默认态，可直接使用
    DVEResourceModelStatusNeedDownlod       = 1, // 资源需要下载
    DVEResourceModelStatusDownloding        = 2, // 资源下载中
    DVEResourceModelStatusDownlodFailed     = 3  // 资源下载失败
};

typedef NS_ENUM(NSUInteger, DVEResourceTag){
    DVEResourceTagNormal = 0,       // 常规资源 抖音资源
    DVEResourceTagAmazing = 1,      // AMAZING资源 //剪同款资源
};

@protocol DVEResourceModelProtocol <NSObject>
////通用//////
///模型唯一标示（必填）
@property (nonatomic, copy) NSString *identifier;
/// 线上资源ID
@property (nonatomic, copy) NSString *resourceId;
///模型路径（当status为DVEResourceModelStatusDefault的时候，必填）
@property (nonatomic, copy) NSString *sourcePath;
///模型名称
@property (nonatomic, copy) NSString *name;
///模型图标
@property (nonatomic, strong) NSURL *imageURL;
///asset中的图片对象（当imageURL返回nil，则获取assetImage做展示）
@property (nonatomic, strong) UIImage *assetImage;
///资源类型 （目前滤镜/特效/调节/滤镜需要指定资源类型）
@property (nonatomic, assign)DVEResourceTag resourceTag;
///美颜/滤镜等的强度默认值
@property (nonatomic, assign) CGFloat defaultValue;

////贴纸/////
///贴纸类型
@property (nonatomic, copy) NSString *stickerType;

////文本//////
///  0代表文字横排，1代表文字竖排
@property (nonatomic, strong) NSNumber *typeSettingKind;
///对齐方式
@property (nonatomic, strong) NSNumber *alignType;
///颜色数组
@property (nonatomic, copy) NSArray *color;
///字体类型
@property (nonatomic, copy) NSDictionary *style;
///文本模板资源依赖
@property (nonatomic, copy) NSArray<id<DVEResourceModelProtocol>> *textTemplateDeps;

////转场动画/////
///是否交叠转场
@property (nonatomic, assign) BOOL overlap;

///画布/////
///画布比例
@property (nonatomic, assign) DVEModuleCanvasType canvasType;

///蒙版////
///不规则图形标示te.g 爱心、五角星等
@property (nonatomic, copy) NSString *mask;


///曲线变速///
@property (nonatomic, copy) NSArray *speedPoints;

///Composer///
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *effectTags;
@property (nonatomic, copy) NSString *effectExtra;

///立即下载
-(void)downloadModel:(void(^)(id<DVEResourceModelProtocol> model))handler;
///资源状态
-(DVEResourceModelStatus)status;

@end

NS_ASSUME_NONNULL_END
