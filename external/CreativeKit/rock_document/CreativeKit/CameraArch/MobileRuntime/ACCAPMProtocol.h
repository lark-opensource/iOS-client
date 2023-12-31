//
//  ACCAPMProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAPMProtocol <NSObject>

+ (void)attachInfo:(nullable id)info forKey:(NSString *)key;
+ (void)attachFilter:(nullable id)filter forKey:(NSString *)key;

@end

FOUNDATION_STATIC_INLINE Class<ACCAPMProtocol> ACCAPM() {
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCAPMProtocol)] class];
}

NS_ASSUME_NONNULL_END
