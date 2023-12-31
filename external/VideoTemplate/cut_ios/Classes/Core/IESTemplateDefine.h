//
//  IESTemplateDefine.h
//  cut_ios
//
//  Created by wangchengyi on 2019/12/20.
//  Copyright © 2019 zhangyeqi. All rights reserved.
//

#ifndef IESTemplateDefine_h
#define IESTemplateDefine_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IESTemplatePlayerStatus) {
    // 空闲状态
    IESTemplatePlayerStatusIdle,
    // 播放状态
    IESTemplatePlayerStatusPlaying,
    // 暂停状态
    IESTemplatePlayerStatusPaused
};

@interface IESCrop: NSObject
@property(nonatomic, assign) float upperLeftX;
@property(nonatomic, assign) float upperLeftY;
@property(nonatomic, assign) float upperRightX;
@property(nonatomic, assign) float upperRightY;
@property(nonatomic, assign) float lowerLeftX;
@property(nonatomic, assign) float lowerLeftY;
@property(nonatomic, assign) float lowerRightX;
@property(nonatomic, assign) float lowerRightY;
@end

typedef NS_ENUM(NSInteger, IESTemplatePlayerVideoAlignMode) {
    IESTemplatePlayerVideoAlignVideo,
    IESTemplatePlayerVideoAlignCanvas,
};

typedef NS_ENUM(NSInteger, IESTemplateVideoType) {
    IESTemplateVideoTypeImage,
    IESTemplateVideoTypeVideo,
};

@interface IESVideoSegment: NSObject
@property(nonatomic, strong) NSString* materialId; // 素材id 定位 project segment 用
@property(nonatomic, assign) NSUInteger targetStartTime; // 排序需要
@property(nonatomic, assign) BOOL isMutable; // true 表示可变，需要用户选择视频填充
@property(nonatomic, assign) IESTemplatePlayerVideoAlignMode alignMode; // 视频素材对齐方式
@property(nonatomic, assign) BOOL isReverse; // 是否需要倒放

@property(nonatomic, assign) NSUInteger width; // 宽
@property(nonatomic, assign) NSUInteger height; // 高
@property(nonatomic, assign) NSUInteger duration; // 时长

@property(nonatomic, strong) NSString* path; // 路径
@property(nonatomic, assign) NSUInteger sourceStartTime; // 时间裁剪起始点
@property(nonatomic, assign) IESTemplateVideoType videoType; //视频类型, 图片或者正常视频
@property(nonatomic, strong) IESCrop* crop; // 空间裁剪区域
@end

@interface IESTextSegment : NSObject

@property(nonatomic, strong) NSString* materialId; // 素材id 定位 project segment 用
@property(nonatomic, strong) NSString* text; // 文本内容
@property(nonatomic, assign) BOOL isMutable; // true 表示可变，需要用户选择视频填充

@end

@interface IESVideoCompileParam: NSObject
// 输出视频宽高
@property(nonatomic, assign) NSUInteger width;
@property(nonatomic, assign) NSUInteger height;
// 视频fps
@property(nonatomic, assign) NSInteger fps;
// 视频比特率
@property(nonatomic, assign) NSUInteger bps;
// 是否支持硬件编码
@property(nonatomic, assign) BOOL supportHWEncoder;

@end
#endif /* IESTemplateDefine_h */
