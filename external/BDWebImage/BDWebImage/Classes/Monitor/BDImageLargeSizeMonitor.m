//
//  BDImageLargeSizeMonitor.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/4/12.
//

#import "BDImageLargeSizeMonitor.h"
#import "BDImage.h"
#import "UIImage+BDWebImage.h"
#import "BDImageMonitorManager.h"

#define kScreenX [[UIScreen mainScreen] bounds].size.width * UIScreen.mainScreen.scale
#define kScreenY [[UIScreen mainScreen] bounds].size.height * UIScreen.mainScreen.scale

static const NSUInteger ImageFileSizeLimitDefault = 20 * 1024 * 1024;

@implementation BDImageLargeSizeMonitor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileSizeLimit = ImageFileSizeLimitDefault;
        _memoryLimit = kScreenX * kScreenY * 4;
    }
    return self;
}

- (void)trackLargeImageMonitor {
    UIView *view = self.requestView;
    UIImage *image = self.requestImage;
    
    // 开关没打开 || 图片加载失败 || view 已被释放 || image 已被释放
    if (!self.monitorEnable || !self.loadSuccess || view == nil || image == nil) {
        return;
    }
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if ([image isKindOfClass:[BDImage class]]) {
        BDImage *bdimg = (BDImage *)image;
        imageWidth = bdimg.originSize.width;
        imageHeight = bdimg.originSize.height;
    }
    CGFloat viewWidth = view.bounds.size.width * UIScreen.mainScreen.scale;
    CGFloat viewHeight = view.bounds.size.height * UIScreen.mainScreen.scale;
    NSUInteger imageCost = [image bd_imageCost];
    
    // 图片尺寸大于展示 view 尺寸的 2 倍以上 || 图片文件大小、图片占用内存大小超过阈值
    if ((imageWidth > 0 && imageHeight > 0 && viewWidth > 0 && viewHeight > 0 && imageWidth * imageHeight > viewWidth * viewHeight * 2)
        || self.fileSize > self.fileSizeLimit
        || imageCost > self.memoryLimit) {
        NSInteger contrast = MIN(((double)imageWidth * 1000) / viewWidth, ((double)imageHeight * 1000) / viewHeight);
        NSString *viewInfo = [self bd_getViewPath:view];
        NSDictionary *attributes = @{@"file_size": @(self.fileSize),
                                     @"view_width": @(viewWidth),
                                     @"view_height": @(viewHeight),
                                     @"image_width": @(imageWidth),
                                     @"image_height": @(imageHeight),
                                     @"ram_size": @(imageCost),
                                     @"url": self.imageURL.absoluteString,
                                     @"contrast": @(contrast),
                                     @"view_info": viewInfo};
        [BDImageMonitorManager trackData:attributes logTypeStr:@"image_monitor_exceed_limit_v2"];
#ifdef DEBUG
        NSLog(@"%@", attributes);
#endif
    }
}

#pragma mark - request view info

- (NSString *)bd_getViewPath:(UIResponder *)view {
    if ([view isKindOfClass:[UIViewController class]]) {
        return NSStringFromClass(view.class);
    }
    if ([view.nextResponder isKindOfClass:[UIView class]]) {
        UIView *parent = (UIView *)view.nextResponder;
        NSArray *childs = parent.subviews;
        return [NSString stringWithFormat:@"%@/%@",[self bd_getViewPath:parent], [self pathIndexOfSameClass:childs child:view]];
    }

    if ([view.nextResponder isKindOfClass:[UIViewController class]]) {
        UIViewController *parent = (UIViewController *)view.nextResponder;
        return [NSString stringWithFormat:@"%@/%@[0]",[self bd_getViewPath:parent], NSStringFromClass(view.class)];
    }

    return NSStringFromClass(view.class);
}

- (NSString *)pathIndexOfSameClass:(NSArray *)items child:(UIResponder *)responder {
    if (items.count <= 1) {
        return [NSString stringWithFormat:@"%@[0]", NSStringFromClass([responder class])];
    }

    NSMutableArray *sameItems = [NSMutableArray new];
    for (NSObject *item in items) {
        if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([item class])]) {
            [sameItems addObject:item];
        }
    }

    NSUInteger index = [sameItems indexOfObject:responder];
    return  [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), (unsigned long)index];
}

@end
