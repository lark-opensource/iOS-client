//
//  BDXLynxImpressionView.m
//  BDXElement
//
//  Created by li keliang on 2020/3/9.
//

#import "BDXLynxImpressionView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView+Bridge.h>

NSNotificationName const BDXLynxImpressionWillManualExposureNotification = @"BDXLynxImpressionWillManualExposureNotification";
NSNotificationName const BDXLynxImpressionLynxViewIDNotificationKey = @"BDXLynxImpressionLynxViewIDNotificationKey";
NSNotificationName const BDXLynxImpressionStatusNotificationKey = @"BDXLynxImpressionStatusNotificationKey";
NSNotificationName const BDXLynxImpressionForceImpressionBoolKey = @"BDXLynxImpressionForceImpressionBoolKey";

@protocol BDXLynxInnerImpressionViewDelegate <NSObject>

@optional
- (void)impression;
- (void)exit;

@end

@interface BDXLynxInnerImpressionView ()

@property (nonatomic,   weak) id<BDXLynxInnerImpressionViewDelegate> delegate;

@end

@implementation BDXLynxInnerImpressionView

- (void)didMoveToWindow
{
    [super didMoveToWindow];

    if (self.window) {
        if ([self.superview respondsToSelector:@selector(bdx_shouldManualExposure)]) {
            if ([(id<BDXLynxImpressionParentView>)self.superview bdx_shouldManualExposure]) {
                return;
            }
        }
        
        [self impression];
    } else {
        [self exit];
    }
}

- (void)impression
{
    if (self.onScreen) {
        return;
    }
    
    _onScreen = YES;
    
    if ([self.delegate respondsToSelector:@selector(impression)]) {
        [self.delegate impression];
    }
}

- (void)exit
{
    if (!self.onScreen) {
        return;
    }
    
    _onScreen = NO;
    
    if ([self.delegate respondsToSelector:@selector(exit)]) {
        [self.delegate exit];
    }
}

@end

@interface BDXLynxImpressionView () <BDXLynxInnerImpressionViewDelegate>

@end

@implementation BDXLynxImpressionView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-impression-view")
#else
LYNX_REGISTER_UI("x-impression-view")
#endif

- (UIView *)createView {
    BDXLynxInnerImpressionView *view = [BDXLynxInnerImpressionView new];
    view.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lynxImpressionWillManualExposureNotification:) name:BDXLynxImpressionWillManualExposureNotification object:nil];
    return view;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

LYNX_PROP_SETTER("impression-percent", impressionPercent, NSInteger)
{
    self.view.impressionPercent = MIN(1, MAX((value / 100.f), 0));
}

#pragma mark - BDXLynxImpressionInnerViewDelegate

- (void)impression {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"impression" targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (void)exit {
    
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"exit" targetSign:[self sign] detail:@{}];
    [self.context.eventEmitter sendCustomEvent:event];
}

#pragma mark -

- (void)lynxImpressionWillManualExposureNotification:(NSNotification *)noti
{
    if ([self.view.superview respondsToSelector:@selector(bdx_shouldManualExposure)]) {
        if ([(id<BDXLynxImpressionParentView>)self.view.superview bdx_shouldManualExposure]) {
            return;
        }
    }
    
    if (![self.context.rootView isKindOfClass:LynxView.class]) {
        return;
    }
    
    NSString *lynxViewId = ((LynxView *)self.context.rootView).containerID;
    if (![noti.userInfo[BDXLynxImpressionLynxViewIDNotificationKey] isEqualToString:lynxViewId]) {
        return;
    }
    
    if ([noti.userInfo[BDXLynxImpressionStatusNotificationKey] isEqualToString:@"show"]) {
        [self.view impression];
    } else if ([noti.userInfo[BDXLynxImpressionStatusNotificationKey] isEqualToString:@"hide"]) {
        [self.view exit];
    }
}

@end
