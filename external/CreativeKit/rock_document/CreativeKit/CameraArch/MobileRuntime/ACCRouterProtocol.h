//
//  ACCRouterProtocol.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/9.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRouterProtocol <NSObject>

- (BOOL)canOpenURLString:(NSString *)URLString;

- (void)transferToURLStringWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@optional

- (UIViewController * _Nullable)viewControllerForURLString:(NSString *)URLString;

@end

FOUNDATION_STATIC_INLINE id<ACCRouterProtocol> ACCRouter() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCRouterProtocol)];
}

NS_ASSUME_NONNULL_END
