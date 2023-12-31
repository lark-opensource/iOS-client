//
//  VideoLivenessTC.m
//  Pods
//
//  Created by zhengyanxin on 2021/3/1.
//

#ifndef VideoLivenessVC_h
#define VideoLivenessVC_h
#import "LivenessTaskController.h"


@interface VideoLivenessTC : LivenessTC

@property (nonatomic, strong) NSData *faceImageData;
@property (nonatomic, strong) NSData *faceWithEnvImageData;
@property (nonatomic, assign) int algoErrorCode;
@property (nonatomic, copy, readonly) NSString *readNumber;
@property (nonatomic, assign, readonly) int interruptTime;

@end

#endif /* VideoLivenessVC_h */
