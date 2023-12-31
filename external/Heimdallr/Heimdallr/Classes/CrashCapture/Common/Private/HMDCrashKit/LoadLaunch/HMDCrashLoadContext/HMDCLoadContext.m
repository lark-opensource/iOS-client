//
//  HMDCLoadContext.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#include "HMDMacro.h"
#import  "HMDCLoadContext.h"
#include "HMDCrashLoadOption+Private.h"

@implementation HMDCLoadContext  {
    HMDCLoadOption _option;
}

- (HMDCLoadOptionRef)option {
    return &_option;
}

- (instancetype)initWithOption:(HMDCLoadOptionRef)option {
    if(self = [super init]) {
        HMDCLoadOption_moveContent(option, &_option);
    }
    return self;
}

+ (instancetype)contextWithOption:(HMDCLoadOptionRef)option {
    return [[self alloc] initWithOption:option];
}

- (void)dealloc {
    HMDCLoadOption_destructContent(&_option);
}

@end
