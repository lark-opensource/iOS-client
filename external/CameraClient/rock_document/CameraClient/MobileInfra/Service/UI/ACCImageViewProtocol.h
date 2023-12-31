//
//  ACCImageViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageViewProtocol <NSObject>

- (void)imageView:(UIImageView *)imageView sethitTestEdgeInsets:(UIEdgeInsets)edgeInsets;

@end

FOUNDATION_STATIC_INLINE id<ACCImageViewProtocol> ACCImageView() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCImageViewProtocol)];
}

NS_ASSUME_NONNULL_END
