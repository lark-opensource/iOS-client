//
//  HMURLSessionManager.h
//  Hermas
//
//  Created by 崔晓兵 on 6/1/2022.
//

#import <Foundation/Foundation.h>
#import <Hermas/HMConfig.h>

NS_ASSUME_NONNULL_BEGIN



@protocol HMNetworkProtocol;

@interface HMURLSessionManager : NSObject <HMNetworkProtocol>

@end

NS_ASSUME_NONNULL_END
