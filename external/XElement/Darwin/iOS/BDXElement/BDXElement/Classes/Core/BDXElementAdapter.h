//
//  BDXElementAdapter.h
//  BDXElement
//
//  Created by miner on 2020/7/13.
//

#import <Foundation/Foundation.h>
#import "BDXElementToastDelegate.h"
#import "BDXElementVolumeDelegate.h"
#import "BDXElementLivePlayerDelegate.h"
#import "BDXElementReportDelegate.h"
#import "BDXElementNetworkDelegate.h"
#import "BDXElementMonitorDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXElementAdapter : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<BDXElementToastDelegate> toastDelegate;
@property (nonatomic, weak) id<BDXElementVolumeDelegate> volumeDelegate;
@property (nonatomic, weak) id<BDXElementLivePlayerDelegate> liveDelegate;
@property (nonatomic, weak) id<BDXElementReportDelegate> reportDelegate;
@property (nonatomic, weak) id<BDXElementNetworkDelegate> networkDelegate;
@property (nonatomic, weak) id<BDXElementMonitorDelegate> monitorDelegate;

@end

@interface BDXElementAdapter (Deprecated)

@property (nonatomic, weak) id<BDXElementLottieDelegate> lottieDelegate;

@end

NS_ASSUME_NONNULL_END
