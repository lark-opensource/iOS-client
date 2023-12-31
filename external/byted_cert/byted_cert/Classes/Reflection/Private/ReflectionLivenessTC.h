//
//  ReflectionLivenessVC.h
//  Pods
//
//  Created by zhengyanixn 2020/12/20.
//

#ifndef ReflectionLivenessVC_h
#define ReflectionLivenessVC_h
#import "LivenessTaskController.h"
#import "ReflectionLiveness_API.h"


@interface ReflectionLivenessTC : LivenessTC

@property (nonatomic, strong) NSData *faceImageData;
@property (nonatomic, strong) NSData *faceWithEnvImageData;
@property (nonatomic, assign) int algoErrorCode;

@end


#endif /* ReflectionLivenessVC_h */
