//
//  HMDOrderFileTracer.m
//  Heimdallr
//
//  Created by maniackk on 2021/11/15.
//

#import "HMDOrderFileTracer.h"
#include "HMDOrderFileTraceData.h"
#include "HMDOrderFileCollectData.h"

@implementation HMDOrderFileTracer



+ (instancetype)sharedInstance {
    static HMDOrderFileTracer *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)startTracer {
    setupOFCollectData();
    heimdallrOrderFileEnabled = YES;
}

- (void)stopTracer {
    heimdallrOrderFileEnabled = NO;
    StartEnd();
}

@end
