//
//  HMDCrashKit+private.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashKit.h"
#if !SIMPLIFYEXTENSION && !EMBED
// PrivateServices
#import "HMDURLProvider.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashKit (Internal)

#if !SIMPLIFYEXTENSION && !EMBED
@property (nonatomic, weak) id<HMDURLHostProvider> _Nullable networkProvider;
#endif

@property (nonatomic, copy) NSString *commitID;

@property (nonatomic, copy) NSString *sdkVersion;

@property (nonatomic,assign) BOOL needEncrypt;

@property (nonatomic,assign) NSTimeInterval launchCrashThreshold;

@property (nonatomic,readonly) BOOL lastTimeCrash;

@property (nonatomic, readonly) NSUInteger lastCrashUsedVM;

@property (nonatomic, readonly) NSUInteger lastCrashTotalVM;

//@property (nonatomic,strong) dispatch_queue_t workQueue;

- (void)requestCrashUpload:(BOOL)needSync;

@end

NS_ASSUME_NONNULL_END
