//
//  HMDDefaultExceptionModuleReporter.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import "HMDDefaultExceptionModuleReporter.h"
#if RANGERSAPM
#import "HMDDefaultExceptionModuleReporter+RangersAPMURLProvider.h"
#else
#import "HMDDefaultExceptionModuleReporter+HMDURLProvider.h"
#endif

@implementation HMDDefaultExceptionModuleReporter

- (id<HMDURLProvider>)moduleURLProvier {
    return self;
}

@end
