//
//   SCSmutableMaterial+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/28.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEResourceAV+iOS.h>
#import <CoreMedia/CoreMedia.h>
#import <NLEPlatform/NLENativeDefine.h>
#import <NLEPlatform/NLEStyleText+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCSubTitle_OC :NSObject
@property(nonatomic,copy)NSString* subTitle;
@property(nonatomic,assign)CMTime startTime;
@property(nonatomic,assign)CMTime endTime;
/// X坐标
@property(nonatomic,assign)CGFloat tranX;

/// Y坐标
@property(nonatomic,assign)CGFloat tranY;

/// 缩放系数
@property(nonatomic,assign)CGFloat scale;

/// 样式
@property(nonatomic,strong)NLEStyleText_OC *styleText;
@end


@interface SCSmutableMaterial_OC : NLEResourceAV_OC

/// 资源路径 必填
@property(nonatomic,copy)NSString* path;

/// 封面路径   非必填
@property(nonatomic,copy)NSString* coverPath;

/// 开始时间 非必填
@property(nonatomic,assign)CMTime startTime;

/// 结束时间 必填
@property(nonatomic,assign)CMTime endTime;

/// 素材时长 必填
@property(nonatomic,assign)CMTime duration;

/// 资源名称 非必填
@property(nonatomic,copy)NSString* resName;

/// 宽 必填
@property(nonatomic,assign)NSInteger resWidth;

/// 高 必填
@property(nonatomic,assign)NSInteger resHeight;

/// 类型 必填
@property(nonatomic,assign)NLEResourceType mediaType;

/// 资源ID 必填
@property(nonatomic,copy)NSString* resourceId;


@end

NS_ASSUME_NONNULL_END
