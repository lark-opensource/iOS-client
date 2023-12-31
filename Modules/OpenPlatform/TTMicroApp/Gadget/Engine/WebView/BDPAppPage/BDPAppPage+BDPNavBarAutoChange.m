//
//  BDPAppPage+BDPNavBarAutoChange.m
//  Timor
//
//  Created by 李论 on 2019/8/12.
//

#import "BDPAppPage+BDPNavBarAutoChange.h"
#import "BDPAppPage.h"
#import <UIKit/UIKit.h>
#import <KVOController/KVOController.h>
#import <objc/runtime.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPAppPageController.h"

static const char *kBDPAppPageInnerDicKey = "BDPNavBarAutoChange";

@implementation BDPAppPage (BDPNavBarAutoChange)

- (NSMutableDictionary *)innerDic
{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &kBDPAppPageInnerDicKey);
    if(!dic) {
        dic = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, &kBDPAppPageInnerDicKey, dic, OBJC_ASSOCIATION_RETAIN);
    }
    return dic;
}

- (void)setBap_scrollOffsetGap:(NSInteger)scrollOffsetGap
{
    [[self innerDic] setValue:@(scrollOffsetGap)
                       forKey:@"scrollOffsetGap"];
}

- (NSInteger)bap_scrollOffsetGap
{
    return [[self innerDic] integerValueForKey:@"scrollOffsetGap" defaultValue:0];
}

- (BOOL)bap_enableNavBarStyleAutoChange
{
    return [[self innerDic] bdp_boolValueForKey:@"enableNavBarStyleAutoChange"];
}

- (void)setBap_enableNavBarStyleAutoChange:(BOOL)enableNavBarStyleAutoChange
{
    if(enableNavBarStyleAutoChange != [self bap_enableNavBarStyleAutoChange]) {

        if(enableNavBarStyleAutoChange) {
            //需要打开监控
            __block CGPoint lastContentOffset = CGPointZero;
            __block CGFloat lastScrollPercentage = 0;
            WeakSelf;
            [self observeWebDidScroll:^(UIScrollView * _Nonnull scroll) {
                StrongSelfIfNilReturn;
                BOOL notify = NO;
                if(!CGPointEqualToPoint(lastContentOffset, CGPointZero)) {

                    CGFloat gap_y = [self bap_scrollOffsetGap];
                    if(lastContentOffset.y < gap_y && scroll.contentOffset.y >= gap_y) {
                        [self handleScrollOverGap:BDPAppScrollViewMoveType_MoveIn];
                        notify = YES;
                    }

                    if(lastContentOffset.y > gap_y && scroll.contentOffset.y <= gap_y) {
                        [self handleScrollOverGap:BDPAppScrollViewMoveType_MoveOut];
                        notify = YES;
                    }

                    CGFloat tempScrollPercentage = scroll.contentOffset.y/MAX(gap_y, 1);
                    if(tempScrollPercentage <= 0.05 ) {
                        //避免不满足临界值，透明的情况
                        tempScrollPercentage = 0.0;
                    }
                    else if (tempScrollPercentage > 1.0) {
                         tempScrollPercentage = 1.0;
                    }

                    if (fabs(tempScrollPercentage - lastScrollPercentage) > 0.03 ) {
                        //避免变化太过频繁
                        lastScrollPercentage = tempScrollPercentage;
                        [self handleScrollPercentageChange:tempScrollPercentage];
                        notify = YES;
                    }
                }
                lastContentOffset = scroll.contentOffset;
                if(notify) {
                    [self notifyNavBarShouldChange];
                }

            }];
        }
        else {
            [self.KVOController removeObserver:self.scrollView forKeyPath:@"contentOffset"];
        }
        [[self innerDic] setValue:@(enableNavBarStyleAutoChange)
                           forKey:@"enableNavBarStyleAutoChange"];
    }
}

- (void)observeWebDidScroll:(BDPAppPageWebDidScroll)scrollCallBack
{
    scrollCallBack = [scrollCallBack copy];
    [self.KVOController observe:self.scrollView keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, UIScrollView*  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        if(scrollCallBack) {
            scrollCallBack(object);
        }
    }];
}

- (BDPAppScrollViewMoveType)bap_curWebScrollStatus
{
    return (BDPAppScrollViewMoveType)[[self innerDic] bdp_intValueForKey:@"curWebScrollStatus"];
}

- (CGFloat)bap_scrollGapPercentage
{
    return [[self innerDic] bdp_floatValueForKey:@"scrollGapPercentage"];
}

- (void)handleScrollOverGap:(BDPAppScrollViewMoveType)moveType
{
    BDPLogInfo(@"handleScrollOverGap %@", @(moveType));
    [[self innerDic]  setValue:@(moveType) forKey:@"curWebScrollStatus"];
}

- (void)handleScrollPercentageChange:(CGFloat)tempScrollPercentage
{
    [[self innerDic]  setValue:@(tempScrollPercentage) forKey:@"scrollGapPercentage"];
}


- (void)notifyNavBarShouldChange
{
    if (self.bap_updateCallBack) {
        self.bap_updateCallBack([self bap_scrollGapPercentage], [self.bap_pageConfig.window navigationBarBgTransparent]);
    }
}

- (BDPAppPageNavBarUpdate)bap_updateCallBack
{
    return [[self innerDic] valueForKey:@"updateCallBack"];
}

- (void)setBap_updateCallBack:(BDPAppPageNavBarUpdate)updateCallBack
{
    [[self innerDic] setValue:[updateCallBack copy] forKey:@"updateCallBack"];
}

- (BOOL)bdp_enableNavBarAutoChangeIfNeed
{
    if ([self.bap_pageConfig.window.navigationStyle isEqualToString:@"default"]) {
        if ([self.bap_pageConfig.window.transparentTitle isEqualToString:@"auto"]) {
            [self setBap_scrollOffsetGap:[self getNavigationHeight] * 2.0];
            [self setBap_enableNavBarStyleAutoChange:YES];
            return YES;
        }
    }

    return NO;
}

- (BOOL)bap_navBarItemColorShouldReverse
{
    if ([self.bap_pageConfig.window.navigationStyle isEqualToString:@"default"]) {
        if ([self.bap_pageConfig.window.transparentTitle isEqualToString:@"auto"]) {

            switch ([self bap_curWebScrollStatus]) {
                case BDPAppScrollViewMoveType_MoveIn:
                {
                    return YES;
                }
                    break;
                case BDPAppScrollViewMoveType_MoveOut:
                {

                }
                    break;

                default:
                    break;
            }
        }
    }

    return NO;
}

- (CGFloat)getNavigationHeight
{
    if (!IsGadgetWebView(self)) {
        NSString *msg = @"please call function when self is BDPAppPage";
        NSString *finalMsg = [NSString stringWithFormat:@"%@,%@", msg, NSStringFromClass(self.class)];
        BDPLogError(finalMsg)
        NSAssert(NO, finalMsg);
        return 0;
    }
    BDPAppPageController *appVC = [(BDPAppPage*)self parentController];
    return [UIApplication sharedApplication].statusBarFrame.size.height + appVC.navigationController.navigationBar.frame.size.height;
}

@end

