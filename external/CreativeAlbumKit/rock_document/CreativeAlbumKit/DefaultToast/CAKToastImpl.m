//
//  CAKToastImpl.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKToastImpl.h"
#import "CAKToast.h"

@implementation CAKToastImpl

- (void)showToast:(NSString *)content
{
    [CAKToast showToast:content];
}

- (void)showError:(NSString *)content
{
    [CAKToast showToast:content withStyle:CAKToastStyleError];
}

- (void)showToast:(NSString *)content onView:(UIView *)view
{
    [CAKToast showToast:content onView:view withStyle:CAKToastStyleNormal];
}

@end
