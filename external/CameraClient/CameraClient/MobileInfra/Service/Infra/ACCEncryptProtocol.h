//
//  ACCEncryptProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/18.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCEncryptProtocol <NSObject>

//- (void *)decodeWithStr:(const char *)src size:(size_t)size;

@end

FOUNDATION_STATIC_INLINE id<ACCEncryptProtocol> ACCEncrypt() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCEncryptProtocol)];
}
