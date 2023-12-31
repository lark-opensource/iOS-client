//
//  CAKLoadingProtocol.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import <Foundation/Foundation.h>
#import "CAKServiceLocator.h"

@protocol CAKTextLoadingViewProtocol <NSObject>

- (void)dismiss;

- (void)dismissWithAnimated:(BOOL)animated;

- (void)startAnimating;

- (void)stopAnimating;

- (void)allowUserInteraction:(BOOL)allow;

@end


@protocol CAKLoadingProtocol <NSObject>

+ (UIView<CAKTextLoadingViewProtocol> * _Nonnull)showLoadingOnView:(UIView * _Nonnull)view title:(nullable NSString *)title animated:(BOOL)animated;

+ (UIView<CAKTextLoadingViewProtocol> * _Nonnull)showLoadingOnView:(UIView * _Nonnull)view title:(nullable NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

@end

FOUNDATION_STATIC_INLINE _Nullable Class<CAKLoadingProtocol> CAKLoading() {
    return [[CAKBaseServiceProvider() resolveObject:@protocol(CAKLoadingProtocol)] class];
}
