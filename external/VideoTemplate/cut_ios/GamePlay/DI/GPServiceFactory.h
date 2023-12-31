//
//  GPServiceFactory.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "GPServiceContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPServiceFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (class, nonatomic, readonly, strong) GPServiceFactory *sharedInstance;
@property (nonatomic, strong) id<GPServiceContainerProtocol> serviceContainer;

@end

FOUNDATION_STATIC_INLINE id<GPNetServiceProtocol> GPNetService() {
    return [GPServiceFactory.sharedInstance.serviceContainer provideGPNetServiceProtocol];
}


NS_ASSUME_NONNULL_END
