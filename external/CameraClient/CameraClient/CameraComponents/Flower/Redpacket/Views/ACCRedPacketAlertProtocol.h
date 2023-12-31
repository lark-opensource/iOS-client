//
//  ACCRedPacketAlertProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/31.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>


@protocol ACCRedPacketAlertProtocol <NSObject>

- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                     image:(nullable UIImage *)image
         actionButtonTitle:(NSString *)actionButtonTitle
         cancelButtonTitle:(nullable NSString *)cancelButtonTitle
               actionBlock:(void (^_Nullable)(void))actionBlock
               cancelBlock:(void (^_Nullable)(void))cancelBlock;

@end


FOUNDATION_STATIC_INLINE id<ACCRedPacketAlertProtocol> ACCRedPacketAlert() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCRedPacketAlertProtocol)];
}
