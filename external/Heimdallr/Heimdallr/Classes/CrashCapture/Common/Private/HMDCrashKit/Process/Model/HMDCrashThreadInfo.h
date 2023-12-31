//
//  HMDCrashThreadInfo.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashFrameInfo.h"
#import "HMDCrashRegisters.h"
#import "HMDCrashModel.h"
#import "HMDCrashEnvironmentBinaryImages.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashThreadInfo : HMDCrashModel

@property(nonatomic, assign) BOOL crashed;

@property(nonatomic, copy) NSArray<NSNumber *> *stackTrace;

@property(nonatomic, strong) HMDCrashRegisters *registers;

@property(nonatomic, copy) NSArray<HMDCrashFrameInfo *> *frames;

@property(nonatomic, copy) NSString *pthreadName;

@property(nonatomic, copy) NSString *queueName;

@property(nonatomic, copy) NSString *threadName;

- (void)generateFrames:(HMDImageOpaqueLoader *)imageLoader;

// update thread name

@end

NS_ASSUME_NONNULL_END
