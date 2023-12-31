//
//  HMDCrashRuntimeInfo.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/18.
//

#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashRuntimeInfo : HMDCrashModel

@property (nonatomic,copy) NSString *selector;
@property (nonatomic,copy) NSArray *crashInfos;

@end

NS_ASSUME_NONNULL_END
