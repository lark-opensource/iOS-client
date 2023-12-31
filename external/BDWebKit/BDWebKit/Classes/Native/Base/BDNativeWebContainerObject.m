//
//  BDNativeWebContainerObject.m
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import "BDNativeWebContainerObject.h"
#import "BDNativeWebBaseComponent.h"
#import "BDNativeWebBaseComponent+Private.h"
#import "UIScrollView+BDNativeWeb.h"
#import "BDNativeWebLogManager.h"

@implementation BDNativeWebContainerObject

-(void)setNativeView:(UIView *)view
{
    if (_nativeView) {
        [_nativeView removeFromSuperview];
    }
    _nativeView = view;
}

-(void)removeNativeView
{
    [_nativeView removeFromSuperview];
    _nativeView = nil;
}

-(void)updateContainer
{
    if (_containerView != nil && _containerView.superview == nil && self.scrollView != nil)
    {
        [self.scrollView addSubview:_containerView];
    }
}

- (void)enableObserverFrameChanged
{
    __weak typeof(self) weakSelf = self;
    [self.scrollView setBdNativeScrollSetFrameBlock:^() {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.containerView.frame = strongSelf.scrollView.bounds;
        [strongSelf.component containerFrameChanged:strongSelf];
    }];
    
    [self.containerView configNativeContainerBeRemovedAction:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            BDNativeInfo(@"container view has been removed");
        });
    }];
}

- (NSMutableDictionary *)checkNativeInfo
{
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    if (_scrollView)
    {
        [resultDic setValue:@(YES) forKey:@"existScroll"];
    }
    if (_containerView)
    {
        [resultDic setValue:@(YES) forKey:@"existContainer"];
    }
    if (_scrollView && _containerView.superview == _scrollView)
    {
        [resultDic setValue:@(YES) forKey:@"containerInScroll"];
    }
    if (_component)
    {
        [resultDic setValue:_component.tagId forKey:@"id"];
        [resultDic setValue:_component.iFrameID forKey:@"iFrameID"];
    }

    return resultDic;
}

- (void)dealloc {
    [self removeNativeView];
}

@end
