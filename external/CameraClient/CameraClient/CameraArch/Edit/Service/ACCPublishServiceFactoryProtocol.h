//
//  ACCPublishServiceFactoryProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import "ACCPublishServiceProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPublishServiceFactoryProtocol <NSObject>

- (id<ACCPublishServiceProtocol>)build;

@end

FOUNDATION_STATIC_INLINE id<ACCPublishServiceFactoryProtocol> ACCPublishServiceFactory() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCPublishServiceFactoryProtocol)];
}


NS_ASSUME_NONNULL_END
