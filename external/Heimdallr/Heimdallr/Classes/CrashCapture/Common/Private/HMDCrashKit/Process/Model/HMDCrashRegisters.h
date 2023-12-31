//
//  HMDCrashRegisters.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashRegisters : HMDCrashModel

@property(nonatomic, copy) NSDictionary *registers;

@end

NS_ASSUME_NONNULL_END
