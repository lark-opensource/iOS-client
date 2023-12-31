//
//  ACCImageThemeProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/9/14.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageThemeProtocol <NSObject>

- (UIImage *)preferDarkImage:(UIImage *)image;

- (UIImage *)preferLightImage:(UIImage *)image;


@end

FOUNDATION_STATIC_INLINE id<ACCImageThemeProtocol> ACCImageTheme() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCImageThemeProtocol)];
}

NS_ASSUME_NONNULL_END
