//
//  HMDOtherSignalLiveKeeper.m
//  CaptainAllred
//
//  Created by somebody on somday
//

#import <Foundation/Foundation.h>
#import "HMDOtherSDKSignal.h"
#import "HMDOtherSDKSignal+Private.h"

@interface HMDOSLKeeper : NSObject
@end @implementation HMDOSLKeeper

- (BOOL)_privateKL {
    return hmd_other_SDK_signal_live_keeper();
}

@end
