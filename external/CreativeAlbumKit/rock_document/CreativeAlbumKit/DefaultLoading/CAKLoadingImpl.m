//
//  CAKLoadingImpl.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKLoadingImpl.h"
#import "CAKTextLoadingView.h"

@implementation CAKLoadingImpl

+ (UIView<CAKTextLoadingViewProtocol> *)showLoadingOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated
{
    return [CAKTextLoadingView showLoadingOnView:view title:title animated:animated];
}


@end
