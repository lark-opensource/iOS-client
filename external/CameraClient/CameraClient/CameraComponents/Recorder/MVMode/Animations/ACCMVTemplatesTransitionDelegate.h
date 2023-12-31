//
//  ACCMVTemplatesTransitionDelegate.h
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import <Foundation/Foundation.h>

#import "ACCSlidePushContextProviderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCMVTemplatesTransitionDelegate : NSObject <UINavigationControllerDelegate>

- (void)wireToViewController:(UIViewController<ACCSlidePushContextProviderProtocol> *)viewController;

@end

NS_ASSUME_NONNULL_END
