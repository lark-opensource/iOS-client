//
//  VideoRecorder.h
//  smash_demo
//
//  Created by liqing on 2020/2/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDCTVideoRecorder : NSObject

@property (nonatomic, strong, readonly) NSURL *outputURL;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithOutputURL:(NSURL *)outputURL;

- (instancetype)initWithOutputURL:(NSURL *)outputURL outputScale:(float)outputScale;

- (instancetype)initWithOutputURL:(NSURL *)outputURL outputScale:(float)outputScale recordAudio:(BOOL)recordAudio;

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(AVMediaType)mediaType;

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler;
- (void)finishWritingWithCompletion:(nullable void (^)(AVAssetWriterStatus status, NSURL *fileURL, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
