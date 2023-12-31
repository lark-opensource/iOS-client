//
//  BDImageSensibleMonitor.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用户感知监控：https://bytedance.feishu.cn/docs/doccnmyioRX2KqLOpXI5QwjlHWB
 1. 通过 ImageView 开始加载图片 -> 图片显示到 ImageView 上
 2. 图片显示时，ImageView 移除屏幕/隐藏，不进行上报
 上报协议：
 图片宽高、View宽高、加载时长、图片来源、图片类型、sdk 版本、图片帧数、图片url、biz_tag、exception_tag、清晰度字段
 */
@interface BDImageSensibleMonitor : NSObject

@property (nonatomic, assign) BOOL monitorWithService;

@property (nonatomic, assign) BOOL monitorWithLogType;

@property (nonatomic, assign) NSInteger index;/** 图片监控的 index ，用来进行简单采样 */

@property (nonatomic, assign) NSInteger from; /** 图片加载来源 */

@property (nonatomic, copy) NSString *bizTag;   /** app 业务标示 */

@property (nonatomic, assign) NSUInteger exceptionTag;   /** app 异常状态标示 */

@property (nonatomic, copy) NSString *imageURL;   /** 图片url */

@property (nonatomic, weak) UIImageView *requestView; /** 展示的 View ，用于获取展示 view 的信息 */

@property (nonatomic, weak) UIImage *requestImage; /** 展示的 image */

-(void)startImageSensibleMonitor;

- (void)trackImageSensibleMonitor;

@end

NS_ASSUME_NONNULL_END
