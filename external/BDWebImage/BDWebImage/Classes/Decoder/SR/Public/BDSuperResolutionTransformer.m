//
//  BDSuperResolutionTransformer.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/11/8.
//

#import "BDSuperResolutionTransformer.h"
#import <pthread.h>
#if __is_target_arch(arm64) || __is_target_arch(arm64e)
#import "BDImageSuperResolution.h"
#endif
#import "BDWebImageError.h"
#import "BDSuperResolutionTransformer.h"
#import "BDWebImageSRError.h"
#import "BDWebImageManager.h"

//判断结果来源
typedef NS_ENUM(NSInteger, BDWebImageSRStatus)
{
    BDWebImageSRStatusSuccess = 0,
    BDWebImageSRStatusFail = 1,///<网络下载
};

@interface BDSuperResolutionTransformer ()

@property (nonatomic, assign) BOOL srFinished;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) NSInteger srDuration;
@property (nonatomic, assign) NSInteger srWidth;
@property (nonatomic, assign) NSInteger srHeight;
@property (nonatomic, assign) NSInteger srStretch;
@property (nonatomic, assign) BDWebImageSRStatus srStatus;
@property (nonatomic, copy) NSString *srType;

@end

@implementation BDSuperResolutionTransformer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.srFinished = NO;
        self.targetSize = CGSizeZero;
        self.srDuration = 0;
        self.srWidth = 0;
        self.srHeight = 0;
        self.srStretch = 3;
        self.srStatus = BDWebImageSRStatusSuccess;
        self.srType = @"VASR";
    }
    return self;
}

- (nonnull NSString *)appendingStringForCacheKey;
{
    return [NSString stringWithFormat:@"BDSuperResolutionTransformer_3x3"];
}

- (nullable UIImage *)transformImageBeforeStoreWithImage:(nullable UIImage *)image;
{
    if (!image) {
        return nil;
    }
    
    if (pthread_main_np()) {
        // does not support super resolution in main thread
        return nil;
    }
    
    BOOL support = [[[BDWebImageManager sharedManager] BDBaseManagerFromOption] isSupportSuperResolution];
    
    CFTimeInterval start = [[NSDate date] timeIntervalSince1970];
    UIImage *srImage = nil;
    NSError *err = nil;
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    if (support && (CGSizeEqualToSize(CGSizeZero, self.targetSize) || (width < self.targetSize.width && height < self.targetSize.height))) {
#if __is_target_arch(arm64) || __is_target_arch(arm64e)
        @synchronized ([BDImageSuperResolution class]) {
            srImage = [BDImageSuperResolution superResolutionImageWithImage:image error:&err];
        }
#else
        err = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: @"The emulator does not support super resolution", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeEmulatorNotSupported) }];
#endif
    } else {
        err = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageSRError userInfo:@{ NSLocalizedDescriptionKey: !support ? @"SR components verify err" : @"The image is too large to require additional super resolution", NSLocalizedFailureReasonErrorKey:@(SRErrorTypeImageTooLarge) }];
    }

    CFTimeInterval duration = ([[NSDate date] timeIntervalSince1970] - start) * 1000;
    self.error = err;
    if (err) {
        self.srStatus = BDWebImageSRStatusFail;
    } else {
        self.srStatus = BDWebImageSRStatusSuccess;
        self.srDuration = (NSInteger)duration;
        self.srWidth = (NSInteger)srImage.size.width;
        self.srHeight = (NSInteger)srImage.size.height;
    }
    self.srFinished = YES;
    if (srImage == nil) {
        srImage = image;
    }
    return srImage;
}

- (NSDictionary *)transformImageRecoder {
    if (!self.srFinished) {
        return @{};
    }
    if (self.srStatus == BDWebImageSRStatusSuccess) {
        return @{
            @"sr_status": @(self.srStatus),
            @"sr_type": self.srType,
            @"sr_width": @(self.srWidth),
            @"sr_height": @(self.srHeight),
            @"sr_duration": @(self.srDuration),
            @"sr_stretch": @(self.srStretch)
        };
    } else {
        return @{
            @"sr_status": @(self.srStatus),
            @"sr_type": self.srType,
            @"sr_err": self.error.localizedDescription ?: @"",
            @"sr_err_key": self.error.localizedFailureReason ?:@""
        };
    }
}

- (BOOL)isAppliedToThumbnail {
    return NO;
}

@end
