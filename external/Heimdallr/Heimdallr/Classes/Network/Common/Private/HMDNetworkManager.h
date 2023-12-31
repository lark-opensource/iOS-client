//
//  HMDUploadManager.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#import <Foundation/Foundation.h>
#import "HMDNetworkProtocol.h"

@interface HMDNetworkManager : NSObject <HMDNetworkProtocol>

+ (instancetype _Nonnull)sharedInstance;

- (void)setCustomNetworkManager:(id<HMDNetworkProtocol> _Nonnull)manager;

- (BOOL)useCustomNetworkManager;

@end
