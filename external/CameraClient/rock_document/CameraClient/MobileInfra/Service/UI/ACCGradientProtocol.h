//
//  ACCGradientProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCGradientProtocol <NSObject>

- (UIView *)addTopGradientViewForViewController:(UIViewController *)vc
                                           View:(UIView *)view
                                      FromColor:(UIColor *)fromColor
                                        toColor:(UIColor *)toColor
                                         height:(CGFloat)height;

- (UIView *)addBottomGradientViewForViewController:(UIViewController *)vc
                                              View:(UIView *)view
                                         FromColor:(UIColor *)fromColor
                                           toColor:(UIColor *)toColor
                                            height:(CGFloat)height;

@end

FOUNDATION_STATIC_INLINE id<ACCGradientProtocol> ACCGradient() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCGradientProtocol)];
}

NS_ASSUME_NONNULL_END
