//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXLIFECYCLETRACKER_H_
#define DARWIN_COMMON_LYNX_LYNXLIFECYCLETRACKER_H_

#import <Foundation/Foundation.h>
#import "LynxGenericReportInfo.h"
#import "LynxViewClient.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxView;
@interface LynxLifecycleTracker : NSObject <LynxViewLifecycle>

@property(nonatomic, strong) LynxGenericReportInfo *genericReportInfo;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXLIFECYCLETRACKER_H_
