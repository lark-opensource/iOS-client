//
//  HMDCrashProcessState.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashProcessState : HMDCrashModel

@property(nonatomic, assign) NSUInteger freeBytes;

@property(nonatomic, assign) NSUInteger appUsedBytes;

@property(nonatomic, assign) NSUInteger totalBytes;

@property(nonatomic, assign) NSUInteger usedBytes;

@property(nonatomic, assign) NSUInteger usedVirtualMemory;

@property(nonatomic, assign) NSUInteger totalVirtualMemory;

@end

NS_ASSUME_NONNULL_END
