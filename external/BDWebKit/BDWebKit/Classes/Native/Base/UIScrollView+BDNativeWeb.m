//
//  UIScrollView+BDNative.m
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/7/17.
//

#import "UIScrollView+BDNativeWeb.h"
#import <objc/runtime.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>

@interface BDNativeLifeObserverObj()

@property (nonatomic, strong) BDScrollDestructAction destructAction;

@end

@implementation BDNativeLifeObserverObj

- (void)dealloc
{
    if (_destructAction) {
        _destructAction();
    }
}

@end

static const char * kScrollViewFrameBlockKey = "kScrollViewFrameBlockKey";
static const char * kBDNativeLifeObserverOjectKey = "kBDNativeLifeObserverOjectKey";

@implementation UIScrollView (BDNativeWeb)

AWELazyRegisterPremainClassCategory(UIScrollView,BDNativeWeb) {
    [self btd_swizzleInstanceMethod:@selector(setContentSize:) with:@selector(setBDNativeContentSize:)];
    [self btd_swizzleInstanceMethod:@selector(setContentOffset:) with:@selector(setBDNativeContentOffset:)];
}

- (void)setBDNativeContentSize:(CGSize)size
{
    [self setBDNativeContentSize:size];
    if (self.bdNativeScrollSetFrameBlock) {
        self.bdNativeScrollSetFrameBlock();
    }
}

- (void)setBDNativeContentOffset:(CGPoint)contentOffset {
    if (self.bdNativeDisableScroll && !self.scrollEnabled && contentOffset.y != 0) {
        // FIX: https://content.bytedance.net/user/feedback/list/?id=372866637
        // 可能在某些情况下 scrollEnabled 为 NO 还是可以修改 contentOffset，这里直接禁止 y 值的修改
        [self setBDNativeContentOffset:CGPointMake(contentOffset.x, 0)];
    } else {
        [self setBDNativeContentOffset:contentOffset];
    }
}

- (void)setBdNativeDisableScroll:(BOOL)bdNativeDisableScroll {
    objc_setAssociatedObject(self, @selector(bdNativeDisableScroll), @(bdNativeDisableScroll), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdNativeDisableScroll {
    return [objc_getAssociatedObject(self, @selector(bdNativeDisableScroll)) boolValue];
}

- (BDNativeScrollFrameBlock)bdNativeScrollSetFrameBlock {
    return objc_getAssociatedObject(self, kScrollViewFrameBlockKey);
}

- (void)setBdNativeScrollSetFrameBlock:(BDNativeScrollFrameBlock)bdNativeScrollSetFrameBlock {
    objc_setAssociatedObject(self, kScrollViewFrameBlockKey, bdNativeScrollSetFrameBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDNativeLifeObserverObj *)bdNativeLifeObject
{
    return objc_getAssociatedObject(self, kBDNativeLifeObserverOjectKey);
}

- (void)setBdNativeLifeObject:(BDNativeLifeObserverObj *)bdNativeLifeObject
{
    return objc_setAssociatedObject(self, kBDNativeLifeObserverOjectKey, bdNativeLifeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)bdNativeConfigScrollDestructAction:(BDScrollDestructAction)descructAction
{
    if (self.bdNativeLifeObject == nil) {
        self.bdNativeLifeObject = [[BDNativeLifeObserverObj alloc] init];
    }
    self.bdNativeLifeObject.destructAction = descructAction;
}
@end
