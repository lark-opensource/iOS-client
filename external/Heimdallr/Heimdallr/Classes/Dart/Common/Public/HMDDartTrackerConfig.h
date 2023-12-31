//
//  HMDDartTrackerConfig.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDTrackerConfig.h"

extern NSString *const _Nonnull kHMDModuleDartTracker; //dart 异常监控

@interface HMDDartTrackerConfig : HMDTrackerConfig

// 在上传Dart异常日志时是否同步上传Alog日志
// Default: NO
@property(nonatomic, assign)BOOL uploadAlog;

@end
