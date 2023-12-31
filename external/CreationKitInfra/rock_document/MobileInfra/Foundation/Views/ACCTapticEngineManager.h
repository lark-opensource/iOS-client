//
//  ACCTapticEngineManager.h
//  CameraClient
//
// Created by Xiong Dian on November 10, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <Foundation/Foundation.h>

@interface ACCTapticEngineManager : NSObject

+ (void)tap;
+ (void)notifySuccess;
+ (void)notifyFailure;
+ (void)notifyWarning;

@end
