//
//  BDImageSensibleMonitor.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/12/2.
//

#import "BDImageSensibleMonitor.h"
#import "BDImage.h"
#import "BDImageMonitorManager.h"

#ifdef BDWebImage_POD_VERSION
static NSString *const kBDWebImagePodVersion = BDWebImage_POD_VERSION;
#else
static NSString *const kBDWebImagePodVersion = @"";
#endif

@interface BDImageSensibleMonitor ()

@property (nonatomic, assign) double imageStartTime;/** 图片加载开始时间 */
@property (nonatomic, assign) double imageEndTime;/** 图片加载结束时间 */

@end

@implementation BDImageSensibleMonitor

static NSInteger bd_monitor_global_index = 0;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.index = ++bd_monitor_global_index;
    }
    return self;
}

-(void)startImageSensibleMonitor {
    self.imageStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void)trackImageSensibleMonitor {
    UIImageView *imageView = self.requestView;
    UIImage *image = self.requestImage;
    
    // view 已被释放 || view 隐藏 || view 不在屏幕上
    if (![self isDisplayedInScreen:imageView]) {
        return;
    }
    _imageEndTime = [[NSDate date] timeIntervalSince1970] * 1000;
    CGFloat imageWidth = image ? image.size.width : 0;
    CGFloat imageHeight = image ? image.size.height : 0;
    CGFloat viewWidth = imageView.bounds.size.width * UIScreen.mainScreen.scale;
    CGFloat viewHeight = imageView.bounds.size.height * UIScreen.mainScreen.scale;
    NSTimeInterval duration = _imageEndTime - _imageStartTime;
    NSUInteger imageCount = 1;
    NSString *imageType = @"unknow";
    if ([image isKindOfClass:[BDImage class]]) {
        BDImage *bdImage = (BDImage *)image;
        imageCount = bdImage.frameCount;
        imageType = imageTypeString(bdImage.codeType);
    }
    
    NSDictionary *attributes = @{
        @"duration": @((NSInteger)duration),
        @"subjective_score": @(0), // 图片主观质量评分 (0, 100]，（预留字段，后面补充）
        @"objective_score": @(0),  // 图片客观质量评分
        @"aesthetic_score": @(0),  // 图片美学评分
        @"clarity": @(0),          // 清晰度
        @"contrast": @(0),         // 图片对比度程度，分数越低表示对比度越低，数值(0, 100)
        @"brightness": @(0),       // 图片平均亮度，值越大表示越亮，数值[0, 255]
        @"color_richness": @(0),   // 图片色彩的丰富程度，值越低表示颜色单一，数值[0, 100]
        @"texture_richness": @(0), // 图片纹理的丰富程度，值越大表示纹理越丰富，数值[0, 255]
    };
    
    NSDictionary *category = @{
        @"from": @(self.from),
        @"image_sdk_version": kBDWebImagePodVersion,
        @"image_type": imageType,
        @"biz_tag": self.bizTag ?: @"",
        @"exception_tag": @(self.exceptionTag) ?: @""
    };
    
    NSDictionary *extra = @{
        @"image_count": @(imageCount),
        @"view_width": @((NSInteger)viewWidth),
        @"view_height": @((NSInteger)viewHeight),
        @"image_width": @((NSInteger)imageWidth),
        @"image_height": @((NSInteger)imageHeight),
        @"timestamp": @((NSInteger)_imageEndTime),
        @"uri": self.imageURL ?: @""};
    
    if (self.monitorWithService) {
        [BDImageMonitorManager trackService:@"image_sensible_monitor" metric:attributes category:category extra:extra];
    }
    if (self.monitorWithLogType) {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if (attributes.count > 0) {
            [data addEntriesFromDictionary:attributes];
        }
        if (category.count > 0) {
            [data addEntriesFromDictionary:category];
        }
        if (extra.count > 0) {
            [data addEntriesFromDictionary:extra];
        }
        [BDImageMonitorManager trackData:data logTypeStr:@"image_sensible_monitor"];
    }
    
#ifdef DEBUG
    NSLog(@"%@", @{
        @"metric": attributes,
        @"Service": @"image_sensible_monitor",
        @"category": category,
        @"extra": extra
    });
#endif
}

//判断View是否显示在屏幕上
- (BOOL)isDisplayedInScreen:(UIImageView *)imageView{
    if(imageView == nil){
        return NO;
    }
    CGRect screenRect = [UIScreen mainScreen].bounds;

    CGRect rect = imageView.frame;
    if(CGRectIsEmpty(rect) || CGRectIsNull(rect)){
        return NO;
    }
    //若view 隐藏
    if(imageView.hidden){
        return NO;
    }
    //若没有superView
    if(imageView.superview == nil){
        return NO;
    }
    //若size 为CGRectZero
    if(CGSizeEqualToSize(rect.size, CGSizeZero)){
        return NO;
    }
    //获取 该view 与window 交叉的Rect
    CGRect intersectionRect = CGRectIntersection(rect, screenRect);
    if(CGRectIsEmpty(intersectionRect) || CGRectIsNull(intersectionRect)){
        return NO;
    }
    
    return YES;
}

@end
