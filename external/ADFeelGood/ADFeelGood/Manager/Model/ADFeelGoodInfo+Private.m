//
//  ADFeelGoodInfo+Private.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/2/2.
//

#import "ADFeelGoodInfo+Private.h"
#import <objc/runtime.h>

@implementation ADFeelGoodInfo (Private)
@dynamic taskID, triggerResult, globalDialog;
@dynamic webviewParams, taskSetting, url, requestTimeoutAt, willOpenBlock, didOpenBlock, didCloseBlock, enableOpenBlock;

- (void)setWebviewParams:(NSDictionary *)webviewParams
{
    objc_setAssociatedObject(self, @selector(webviewParams), webviewParams, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSDictionary *)webviewParams
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTaskSetting:(NSDictionary *)taskSetting
{
    objc_setAssociatedObject(self, @selector(taskSetting), taskSetting, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSDictionary *)taskSetting
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setUrl:(NSURL *)url
{
    objc_setAssociatedObject(self, @selector(url), url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSURL *)url
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRequestTimeoutAt:(NSDate *)requestTimeoutAt
{
    objc_setAssociatedObject(self, @selector(requestTimeoutAt), requestTimeoutAt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSDate *)requestTimeoutAt
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWillOpenBlock:(BOOL (^)(ADFeelGoodInfo * _Nonnull))willOpenBlock
{
    objc_setAssociatedObject(self, @selector(willOpenBlock), willOpenBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (BOOL (^)(ADFeelGoodInfo * _Nonnull))willOpenBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDidOpenBlock:(void (^)(BOOL, ADFeelGoodInfo * _Nonnull, NSError * _Nonnull))didOpenBlock
{
    objc_setAssociatedObject(self, @selector(didOpenBlock), didOpenBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(BOOL, ADFeelGoodInfo * _Nonnull, NSError * _Nonnull))didOpenBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDidCloseBlock:(void (^)(BOOL, ADFeelGoodInfo * _Nonnull))didCloseBlock
{
    objc_setAssociatedObject(self, @selector(didCloseBlock), didCloseBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(BOOL, ADFeelGoodInfo * _Nonnull))didCloseBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setEnableOpenBlock:(BOOL (^)(ADFeelGoodInfo * _Nonnull))enableOpenBlock
{
    objc_setAssociatedObject(self, @selector(enableOpenBlock), enableOpenBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (BOOL (^)(ADFeelGoodInfo * _Nonnull))enableOpenBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
