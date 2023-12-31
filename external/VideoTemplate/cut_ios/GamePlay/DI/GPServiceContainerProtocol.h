//
//  GPServiceContainerProtocol.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "GPNetServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GPServiceContainerProtocol <NSObject>

/// 网络能力
- (id<GPNetServiceProtocol>)provideGPNetServiceProtocol;

@end

NS_ASSUME_NONNULL_END
