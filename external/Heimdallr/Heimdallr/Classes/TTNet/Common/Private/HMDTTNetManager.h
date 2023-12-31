//
//  HMDTTNetUploader.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#import <Foundation/Foundation.h>
#import "HMDNetworkProtocol.h"

@interface HMDTTNetManager : NSObject<HMDNetworkProtocol>

- (BOOL)isChromium;

@end
