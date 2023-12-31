//
//  DVEResourcePickerProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/5/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DVEResourcePickerModelType) {
    DVEResourceModelPickerTypeNone      = 0,
    DVEResourceModelPickerTypeVideo     = 1,
    DVEResourceModelPickerTypeImage     = 2,
    DVEResourceModelPickerTypeLivePhoto = 3,
    DVEResourceModelPickerTypeGIf       = 4,
    DVEResourceModelPickerTypeAudio     = 5,
};

@protocol DVEResourcePickerModel <NSObject>

- (DVEResourcePickerModelType)type;
- (void)setURL:(NSURL *)URL;
- (void)setVideoAsset:(AVURLAsset *)videoAsset;
- (NSURL *)URL;
- (AVURLAsset * _Nullable)videoAsset;
- (UIImage *)image;
- (CMTime)imageDuration;

@optional
- (float)videoSpeed;
- (NSData *)imageData;
- (AVAsset *)imageAsset;
- (NSString *)resourceName;
- (BOOL)isGIFImage;

@end

typedef void (^DVEResourcePickerCompletion)(NSArray<id<DVEResourcePickerModel>> *resources,
                                            NSError * _Nullable error,
                                            BOOL cancel);

@protocol DVEResourcePickerProtocol <NSObject>

@optional

- (void)pickResourcesWithDurationList:(NSArray<NSNumber *> *)durationList
                           completion:(DVEResourcePickerCompletion)completion;
- (void)pickResourcesWithCompletion:(DVEResourcePickerCompletion)completion;
- (void)pickSingleResourceWithCompletion:(DVEResourcePickerCompletion)completion;
- (void)pickVideoResourcesWithCompletion:(DVEResourcePickerCompletion)completion;
- (void)pickSingleImageResourceWithCompletion:(DVEResourcePickerCompletion)completion;
- (void)pickSingleCropImageResourceWithCompletion:(DVEResourcePickerCompletion)completion;
- (void)pickSingleResourceWithLimitDuration:(NSInteger)duration completion:(DVEResourcePickerCompletion)completion;
- (UIViewController*)pickAudioResourceWithCompletion:(DVEResourcePickerCompletion)completion;
@end

NS_ASSUME_NONNULL_END
