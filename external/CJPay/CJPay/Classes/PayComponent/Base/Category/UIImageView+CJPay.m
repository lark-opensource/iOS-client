//
//  UIImageView+CJPay.m
//  CJPay
//
//  Created by 王新华 on 2019/6/2.
//

#import "UIImageView+CJPay.h"
#import "NSBundle+CJPay.h"
#import "UIImage+CJPay.h"
#import "UIColor+CJPay.h"
#import "CJPayMonitor.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayPrivateServiceHeader.h"

#import <objc/runtime.h>
#import <BDWebImage/UIImageView+BDWebImage.h>
#import <BDWebImage/BDWebImageRequest.h>

static void *imageUrlStringKey = &imageUrlStringKey;

@interface UIImageView (CJPay)

@property (nonatomic, copy) NSString *imageUrlString;
@property (nonatomic, strong) UIImageView *loadingImageView;

@end


@implementation UIImageView(CJPay)

- (void)setSilentImage:(UIImage *)silentImage {
    objc_setAssociatedObject(self, @selector(silentImage), silentImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)silentImage {
    return objc_getAssociatedObject(self, @selector(silentImage));
}

- (void)setLoadingImageView:(UIImageView *)loadingImageView {
    objc_setAssociatedObject(self, @selector(loadingImageView), loadingImageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImageView *)loadingImageView {
    return objc_getAssociatedObject(self, @selector(loadingImageView));
}

- (void)cj_startLoading {

    [self.loadingImageView removeFromSuperview];
    self.loadingImageView = [UIImageView new];
    [self.superview addSubview:self.loadingImageView];
    self.loadingImageView.frame = self.frame;
    [self.loadingImageView cj_setImage:@"cj_withdraw_method_loading_icon"];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.fromValue = @(0.0f);
    animation.toValue = @(M_PI * 2);
    animation.duration = 0.6;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    [self.loadingImageView.layer addAnimation:animation forKey:@"loading_image"];
    self.hidden = YES;
};

- (void)cj_stopLoading {

    self.hidden = NO;
    [self.loadingImageView.layer removeAnimationForKey:@"loading_image"];
    [self.loadingImageView removeFromSuperview];
}

- (UIImage *)p_createClearImage {
    if (!self.image) {
        return nil;
    }
    UIImage *clearImage = [UIImage cj_imageWithColor:[UIColor clearColor]];
    [clearImage cj_scaleToSize:self.image.size];
    return clearImage;
}

- (nullable BDWebImageRequest *)cj_setImageWithURL:(nonnull NSURL *)imageURL placeholder:(nullable UIImage *)placeholder {
    return [self cj_setImageWithURL:imageURL placeholder:placeholder completion:nil];
}

- (BDWebImageRequest *)cj_setImageWithURL:(NSURL *)imageURL placeholder:(nullable UIImage *)placeholder completion:(nullable void (^)(UIImage *image, NSData * data, NSError *error))completion {
    CJPayLogAssert([imageURL isKindOfClass:[NSURL class]], @"imageURL must be a NSURL class");
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    return [self bd_setImageWithURL:imageURL
                        placeholder:placeholder
                            options:BDImageRequestDefaultOptions
                           progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {}
                         completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        CFTimeInterval costTime = endTime - startTime;
        NSString *url;
        if ([imageURL isKindOfClass:[NSURL class]]) {
            url = imageURL.absoluteString;
        } else if ([imageURL isKindOfClass:[NSString class]]) {
            url = (NSString *)imageURL;
        } else {
            url = @"unkown";
        }
        if (image == nil) {
            [CJMonitor trackService:@"wallet_rd_url_image_load_fail"
                           category:@{@"url" :  CJString(url)}
                              extra:@{}];
        } else {
            // 0.5计算得到的更接近图片文件实际大小
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imgData = UIImageJPEGRepresentation(image, 0.5);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CJTracker event:@"wallet_rd_network_success_info"
                              params:@{@"url": CJString(url),
                                       @"status": @(error.code),
                                       @"reason": CJString(error.description),
                                       @"length": @(imgData ? imgData.length : 0),
                                       @"time": @(costTime * 1000)
                                     }];
                });
            });
        }
        CJ_CALL_BLOCK(completion, image, data, error);
    }];
}

- (nullable BDWebImageRequest *)cj_setImageWithURL:(nonnull NSURL *)imageURL {
    return [self cj_setImageWithURL:imageURL placeholder:nil];
}

- (void)cj_setImage:(NSString *)imageName {
    [self cj_setImage:imageName completion:nil];
}


- (void)cj_setImage:(NSString *)imageName completion:(nullable void (^)(BOOL isSuccess))completion {
    __block NSString *urlString = [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService)i_getImageUrlOrName:imageName];
    self.imageUrlString = urlString;//设置最新图片URL
    if (!Check_ValidString(urlString)) {
        CJ_CALL_BLOCK(completion,NO);
        return;
    }
    NSString *preStr = [NSString stringWithFormat:@"CJ%@//", UP_Gecko];
    if ([urlString hasPrefix:@"http"]) {
        [self bd_setImageWithURL:[NSURL URLWithString:urlString] placeholder:nil options:BDImageRequestDefaultOptions |BDImageRequestSetDelaySetImage completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if(error) {
                [CJMonitor trackService:@"wallet_rd_cdn_img_fail"
                               category:@{@"image_name" : CJString(imageName),
                                          @"url" : CJString(request.currentRequestURL.absoluteString)
                               }
                                  extra:@{}];
                CJ_CALL_BLOCK(completion,NO);
            }else {
                if ([urlString isEqualToString:self.imageUrlString]) {
                    [self setImage:image];
                    CJ_CALL_BLOCK(completion,YES);
                } else {
                    CJ_CALL_BLOCK(completion,NO);
                }
            }
        }];
        [CJMonitor trackService:@"wallet_rd_image_source"
                       category:@{@"image_name" : CJString(imageName),
                                  @"source" : @"cdn"}
                          extra:@{}];
    } else if([urlString hasPrefix:preStr]){
        NSURL *url = [NSURL fileURLWithPath:[urlString stringByReplacingOccurrencesOfString:preStr withString:@""]];
        [self bd_setImageWithURL:url
                     placeholder:nil
                         options:BDImageProgressiveDownload|BDImageNoRetry
                      completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if(error) {
                CJ_CALL_BLOCK(completion,NO);
            }else {
                CJ_CALL_BLOCK(completion,YES);
            }
        }];
        [CJMonitor trackService:@"wallet_rd_image_source"
                       category:@{@"image_name" : CJString(imageName),
                                  @"source" : DW_gecko}
                          extra:@{}];
    } else if ([urlString hasPrefix:@"#"]){
        self.image = [UIImage cj_imageWithColor:[UIColor cj_colorWithHexString:urlString]];
        CJ_CALL_BLOCK(completion,YES);
    }
    else {
        self.image = [UIImage cj_imageWithName:urlString];
        if (!self.image) {
            [CJMonitor trackService:@"wallet_rd_local_img_loss"
                           category:@{@"image_name" : CJString(imageName)}
                              extra:@{}];
            CJ_CALL_BLOCK(completion,NO);
        } else {
            CJ_CALL_BLOCK(completion,YES);
        }
        [CJMonitor trackService:@"wallet_rd_image_source"
                       category:@{@"image_name" : CJString(imageName),
                                  @"source" : @"local"}
                          extra:@{}];
    }
}

#pragma mark - imageUrlString

-(void)setImageUrlString:(NSString *)str
{
    objc_setAssociatedObject(self, &imageUrlStringKey, str, OBJC_ASSOCIATION_COPY);
}

-(NSString *)imageUrlString
{
    return objc_getAssociatedObject(self, &imageUrlStringKey);
}

@end
