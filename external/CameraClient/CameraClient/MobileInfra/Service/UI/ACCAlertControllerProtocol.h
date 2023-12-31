//
//  ACCAlertControllerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/9/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAlertControllerProtocol <NSObject>

- (void)showAlertController:(UIAlertController *)alertController;

- (void)showAlertWithTitle:(nullable NSString *)title
               message:(nullable NSString *)message
        preferredStyle:(UIAlertControllerStyle)preferredStyle
     cancelButtonTitle:(nullable NSString *)cancelButtonTitle
destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
     otherButtonTitles:(nullable NSArray *)otherButtonTitles
              tapBlock:(nonnull void (^)(UIAlertController * _Nullable controller, UIAlertAction * _Nullable action, NSInteger buttonIndex))tapBlock;

@end

FOUNDATION_STATIC_INLINE id<ACCAlertControllerProtocol> ACCAlertController() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCAlertControllerProtocol)];
}

NS_ASSUME_NONNULL_END
