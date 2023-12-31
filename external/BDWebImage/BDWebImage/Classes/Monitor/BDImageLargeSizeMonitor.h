//
//  BDImageLargeSizeMonitor.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 大图监控：
 1. 图片尺寸是展示View尺寸的2倍以上
 2. 图片下载大小超过20Mb
 3. 图片内存大小超过 screenPixel * 4
 上报协议：
 文件大小、图片宽高、View宽高、内存大小、图片url、图片和View的宽高比（千分比）、View信息（View树）
 */
@interface BDImageLargeSizeMonitor : NSObject

@property (nonatomic, assign) BOOL monitorEnable;

@property (nonatomic, assign) NSUInteger fileSizeLimit; /** 大图文件大小限制，默认 20 MB */

@property (nonatomic, assign) NSUInteger memoryLimit; /** 大图内存大小限制，默认 屏幕分辨率 * 4 */

@property (nonatomic, assign) BOOL loadSuccess;  /** 图片加载成功才检测大图 */

@property (nonatomic, strong) NSURL *imageURL;   /** 图片url */

@property (nonatomic, assign) double fileSize;   /** 图片大小 单位byte */

@property (nonatomic, weak) UIView *requestView; /** 展示的 View ，用于获取展示 view 的信息 */

@property (nonatomic, weak) UIImage *requestImage; /** 展示的 image */

- (void)trackLargeImageMonitor;

@end

NS_ASSUME_NONNULL_END
