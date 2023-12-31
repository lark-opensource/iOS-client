//
//  HMDCrashStorage.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashStorage : HMDCrashModel

@property (nonatomic,assign) unsigned long long free;
@property (nonatomic,assign) unsigned long long total;

@end

NS_ASSUME_NONNULL_END
