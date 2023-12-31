//
//  CAKToastProtocol.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import <Foundation/Foundation.h>
#import "CAKServiceLocator.h"

@protocol CAKToastProtocol <NSObject>

- (void)showToast:(NSString * _Nullable)content;

- (void)showError:(NSString * _Nullable)content;

- (void)showToast:(NSString * _Nullable)content onView:(UIView * _Nullable)view;

@end

FOUNDATION_STATIC_INLINE _Nullable id<CAKToastProtocol> CAKToastShow() {
    return [CAKBaseServiceProvider() resolveObject:@protocol(CAKToastProtocol)];
}
