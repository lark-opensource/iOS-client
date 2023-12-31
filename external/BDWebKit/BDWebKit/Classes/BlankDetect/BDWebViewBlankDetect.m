//
//  BDWebViewDetectBlankContent.m
//  BDWebKit
//
//  Created by 杨牧白 on 2020/3/13.
//

#import "BDWebViewBlankDetect.h"
#import <WebKit/WebKit.h>

#define DetectMonitorMgrInstance [BDWebViewBlankDetectMonitorMgr shareInstance]

@interface BDWebViewBlankDetectMonitorMgr:NSObject

@property (nonatomic, strong) NSMutableSet *monitors;

+ (instancetype)shareInstance;
- (void)addBlankDetectMonitorListener:(id<BDWebViewBlankDetectListenerDelegate>)monitorListener;

@end

@implementation BDWebViewBlankDetectMonitorMgr

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDWebViewBlankDetectMonitorMgr * manager;
    dispatch_once(&onceToken, ^{
        manager = [[BDWebViewBlankDetectMonitorMgr alloc] init];
    });
    return manager;
}

- (NSMutableSet *)monitors {
    if(!_monitors) {
        _monitors = [[NSMutableSet alloc] init];
    }
    return _monitors;
}

- (void)addBlankDetectMonitorListener:(id<BDWebViewBlankDetectListenerDelegate>)monitorListener {
    if (monitorListener) {
        [self.monitors addObject:monitorListener];
    }
}

- (void)reportDetectResult:(UIView *)webView isBlank:(BOOL)isBlank detectType:(BDDetectBlankMethod)detectType detectImage:(UIImage *)image error:(NSError *)error detectStartTime:(NSDate *)startTime {
    NSTimeInterval cost = [[NSDate date] timeIntervalSinceDate:startTime];
    [_monitors enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(onDetectResult:isBlank:detectType:detectImage:error:costTime:)]) {
            [obj onDetectResult:webView isBlank:isBlank detectType:detectType detectImage:image error:error costTime:cost];
        }
    }];
}

@end


@implementation BDWebViewBlankDetect

//wk iOS 11 新检测接口
+ (void)detectBlankByNewSnapshotWithWKWebView:(WKWebView *)wkWebview CompleteBlock:(void(^)(BOOL isBlank, UIImage *image, NSError *error)) block {
    if (!block) {
        return;
    }
    
    NSDate *detectStartTime = [NSDate date];
    if (@available(iOS 11.0, *)) {
        if ([wkWebview isKindOfClass:[WKWebView class]]) {
            __weak WKWebView *weakWebView = wkWebview;
            WKSnapshotConfiguration* configuration = [[WKSnapshotConfiguration alloc] init];
            configuration.rect = CGRectIntersection(wkWebview.bounds, [UIScreen mainScreen].bounds);
            [wkWebview takeSnapshotWithConfiguration:configuration completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
                __strong WKWebView *strongWebView = weakWebView;
                if (error) {
                    [DetectMonitorMgrInstance reportDetectResult:strongWebView isBlank:NO detectType:eBDDetectBlankMethodNew detectImage:nil error:error detectStartTime:detectStartTime];
                    block(NO, nil, error);
                } else if (snapshotImage) {
                    UIColor *color = wkWebview.backgroundColor;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        BOOL isBlank = [BDWebKitUtil checkWebContentBlank:snapshotImage withBlankColor:color];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [DetectMonitorMgrInstance reportDetectResult:strongWebView isBlank:isBlank detectType:eBDDetectBlankMethodNew detectImage:snapshotImage error:nil detectStartTime:detectStartTime];
                            block(isBlank, snapshotImage, nil);
                        });
                    });
                }
            }];
            return;
        }
    }
    
    NSError *error = [NSError errorWithDomain:@"BDWebViewDetectBlank" code:eBDDetectBlankUnsupportError userInfo:@{NSLocalizedDescriptionKey:@"no support detect blank"}];
    [DetectMonitorMgrInstance reportDetectResult:wkWebview isBlank:NO detectType:eBDDetectBlankMethodNew detectImage:nil error:error detectStartTime:detectStartTime];
    block ? block(NO, nil, error) : nil;
    
}

//旧检测接口
+ (void)detectBlankByOldSnapshotWithView:(UIView *)view CompleteBlock:(void(^)(BOOL isBlank, UIImage *image, NSError *error)) block {
    if (!block) {
        return;
    }
    NSDate *detectStartTime = [NSDate date];
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (image == nil) {
        NSError *error = [NSError errorWithDomain:@"BDWebViewDetectBlank" code:eBDDetectBlankStatusImageError userInfo:@{NSLocalizedDescriptionKey:@"image is nil"}];
        [DetectMonitorMgrInstance reportDetectResult:view isBlank:NO detectType:eBDDetectBlankMethodOld detectImage:nil error:error detectStartTime:detectStartTime];
        block(NO, nil, error);
        return ;
    }
    
    UIColor *color = view.backgroundColor;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL blank = [BDWebKitUtil checkWebContentBlank:image withBlankColor:color];
        dispatch_async(dispatch_get_main_queue(), ^{
            [DetectMonitorMgrInstance reportDetectResult:view isBlank:blank detectType:eBDDetectBlankMethodOld detectImage:image error:nil detectStartTime:detectStartTime];
            block(blank, image, nil);
        });
    });
}

+ (void)addBlankDetectMonitorListener:(id<BDWebViewBlankDetectListenerDelegate>)monitorListener {
    [[BDWebViewBlankDetectMonitorMgr shareInstance] addBlankDetectMonitorListener:monitorListener];
}

@end
