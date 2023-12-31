//
//  ACCRecorderEvent.h
//  Pods
//
//  Created by haoyipeng on 2020/6/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <TTVideoEditor/HTSVideoData.h>
#import "ACCRecorderLivePhotoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecorderEvent <NSObject>

@optional
- (void)onCaptureStillImageWithImage:(UIImage *)image error:(NSError *)error;
- (void)onStartExportVideoDataWithData:(HTSVideoData *)data;
- (void)onFinishExportVideoDataWithData:(HTSVideoData *)data error:(NSError *)error;
- (void)onWillStartVideoRecordWithRate:(CGFloat)rate;
- (void)onWillPauseVideoRecordWithData:(HTSVideoData *)data;
- (void)onWillStartLivePhotoRecordWithConfig:(id<ACCLivePhotoConfigProtocol>)config;

@end

NS_ASSUME_NONNULL_END
