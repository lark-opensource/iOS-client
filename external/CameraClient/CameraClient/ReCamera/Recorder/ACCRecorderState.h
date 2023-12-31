//
//  ACCRecorderState.h
//  CameraClient
//
//  Created by leo on 2019/12/17.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <TTVideoEditor/HTSVideoData.h>
#import <TTVideoEditor/IESMMCaptureOptions.h>
#import "ACCRecorderDefine.h"
#import <CameraClient/ACCState.h>
#import <CameraClient/ACCResult.h>

@interface ACCRecorderState : MTLModel

#pragma mark - Status
@property (nonatomic, assign) ACCRecorderMode recordMode;
@property (nonatomic, assign) ACCRecorderStatus status;
@property (nonatomic, assign) NSUInteger currentIdx;
@property (nonatomic, assign) CGFloat totalDuration;

#pragma mark - Result
// 存在多次导出的可能，这里计数方便监听方diff，重置为ready时清0
@property (nonatomic, assign) NSUInteger exportTime;
@property (nonatomic, nullable) ACCResult<UIImage *> *imageResult;
@property (nonatomic, nullable) ACCResult<HTSVideoData *> *videoResult;

@property (nonatomic, nullable) ACCResult<id> *startResult;
@property (nonatomic, nullable) ACCResult<id> *pauseResult;
@property (nonatomic, nullable) ACCResult<UIImage *> *extractResult;

@end

