//
//  CJPayWebViewBlankDetect.m
//  Aweme
//
//  Created by ByteDance on 2023/7/12.
//

#import "CJPayWebViewBlankDetect.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"

@implementation CJPayBlankDetectContext
@end

@implementation CJPayWebViewBlankDetect

#pragma mark - Blank Detection

+ (void)blankDetectionWithWebView:(WKWebView *)webView context:(CJPayBlankDetectContext *)context
{
    if (!webView) {
        CJPayLogInfo(@"[WebViewMonitor][Enhance] Blank detection is terminated, webView or detectionRect is null.")
        return;
    }
    
    @CJWeakify(self)
    CFTimeInterval snapshotBeginTime = CACurrentMediaTime();
    [self snapshotWithWebView:webView completion:^(NSError * _Nonnull error, UIImage * _Nonnull image, NSInteger shotDuration) {
        if (error || image == nil) {
            CJPayLogInfo(@"[WebViewMonitor][Enhance] Snapshot error:%@", error);
            return;
        }

        CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].currentSettings.containerConfig;
        NSInteger colorDiff = containerConfig.colorDiff;
        NSString *host = webView.URL.host;
        NSString *path = webView.URL.path;
        NSString *url = [webView.URL absoluteString];
        NSString *loadFinished = webView.isLoading ? @"1" : @"0";
        NSTimeInterval stayTime = context.stayTime;
        NSString *isLoadingViewShowing = context.isLoadingViewShowing ? @"1" : @"0";
        NSString *isErrorViewShowing = context.isErrorViewShowing ? @"1" : @"0";

        @CJStrongify(self)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL isBlank = [self imageIsPureColor:image customColorDiff:colorDiff];
            NSDictionary *metric = @{@"duration" : @((CACurrentMediaTime() - snapshotBeginTime) * 1000),
                                     @"stay_time" : @(stayTime)
                                    };
            NSDictionary *category = @{
                @"host": CJString(host),
                @"path": CJString(path),
                @"url": CJString(url),
                @"is_blank": isBlank ? @"1" : @"0",
                @"load_finished": CJString(loadFinished),
                @"show_loading_view": CJString(isLoadingViewShowing),
                @"show_error_view": CJString(isErrorViewShowing)
            };
            [CJMonitor trackService:@"wallet_rd_webview_new_blank_screen" metric:metric category:category extra:@{}];
            CJPayLogInfo(@"[WebViewMonitor][Enhance] BlankDetect isBlank:%@", @(isBlank));
        });
    }];
}

// 截屏
+ (void)snapshotWithWebView:(WKWebView *)webView completion:(void (^)(NSError * error, UIImage *image, NSInteger shotDuration))completion {
    if (!completion) {
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        __block BOOL callBackComplete = NO;
        WKSnapshotConfiguration *config = [[WKSnapshotConfiguration alloc] init];
        config.rect = webView.bounds;
        [webView takeSnapshotWithConfiguration:config completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
            if (!callBackComplete) {
                callBackComplete = YES;
                if (completion) {
                    completion(error, snapshotImage, 0);
                }
            }
        }];
    } else {
        if (completion) {
            NSError *error = [NSError errorWithDomain:CJPayErrorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"系统小于11", nil)}];
            completion(error, nil, 0);
        }
    }
}

+ (BOOL)imageIsPureColor:(UIImage *)image customColorDiff:(NSInteger)customColorDiff {
    if (!image) {
        return NO;
    }
    
    UIGraphicsEndImageContext();
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    __block CFDataRef pixelData = NULL;
    @onExit{
        if (pixelData != NULL) {
            CFRelease(pixelData);
        }
    };

    @try {
        pixelData = CGDataProviderCopyData(provider);
    } @catch (NSException *exception) {
        return NO;
    }

    if (pixelData == NULL) {
        return NO;
    }

    const UInt8 *data = CFDataGetBytePtr(pixelData);
    long dataLength = CFDataGetLength(pixelData);
    
    return [self calculateIsPureColor:(unsigned char *)data dataLength:dataLength customColorDiff:customColorDiff];
}

+ (BOOL)calculateIsPureColor:(unsigned char *)data dataLength:(long)dataLength customColorDiff:(NSInteger)customColorDiff {
    int numberOfColorComponents = 4; // R,G,B, and A

    NSInteger maxRed = 0;
    NSInteger maxBlue = 0;
    NSInteger maxGreen = 0;
    NSInteger minRed = 255;
    NSInteger minBlue = 255;
    NSInteger minGreen = 255;
    
    double sqrtColorDiff = floor(sqrt(customColorDiff));

    for (long i = 0; i < (dataLength); i += numberOfColorComponents) {
        if (data[i+3] != 0) {
            UInt8 red = data[i];
            UInt8 green = data[i+1];
            UInt8 blue = data[i+2];
            
            minRed = MIN(red, minRed);
            minGreen = MIN(green, minGreen);
            minBlue = MIN(blue, minBlue);

            maxRed = MAX(red, maxRed);
            maxGreen = MAX(green, maxGreen);
            maxBlue = MAX(blue, maxBlue);
            
            // 这是时候必定大于75的阈值
            if ((maxRed - minRed) > sqrtColorDiff
                || (maxBlue - minBlue) > sqrtColorDiff
                || (maxGreen - minGreen) > sqrtColorDiff) {
                return NO;
            }
        }
    }

    double result = pow((maxRed - minRed), 2) + pow((maxBlue - minBlue), 2) + pow((maxGreen - minGreen), 2);
    
    if (result > customColorDiff) {
        return NO;
    }
    
    return YES;
}

@end
