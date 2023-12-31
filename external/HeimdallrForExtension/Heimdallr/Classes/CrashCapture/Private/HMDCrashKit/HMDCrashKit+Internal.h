//
//  HMDCrashKit+private.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashKit.h"
#if !SIMPLIFYEXTENSION
#import "HMDModuleNetworkManager.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashKit (Internal)

#if !SIMPLIFYEXTENSION
@property(nonatomic, weak) id<HMDModuleNetworkProvider> networkProvider;
#endif

@property(nonatomic, copy) NSString *commitID;

@property(nonatomic, copy) NSString *sdkVersion;

@property (nonatomic,assign) BOOL needEncrypt;

@property (nonatomic,assign) NSTimeInterval launchCrashThreshold;

@property (nonatomic,readonly) BOOL lastTimeCrash;

@property (nonatomic,strong) dispatch_queue_t workQueue;

@end

NS_ASSUME_NONNULL_END
