//
//  BDCTFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BDCTFlow.h"
#import "BDCTFlowContext.h"
#import "BDCTAPIService.h"
#import "BytedCertInterface.h"
#import "BDCTEventTracker.h"
#import "UIViewController+BDCTAdditions.h"
#import "BDCTDisablePanGestureViewController.h"
#import "BytedCertManager+Private.h"

#import <objc/runtime.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDModel/BDMappingStrategy.h>
#import <BDModel/BDModel.h>
#import <BDAssert/BDAssert.h>

#define BDCTTimestamp (CACurrentMediaTime() * 1000)


@implementation UIViewController (BDCTFlowAdditions)

- (BDCTFlow *)bdct_flow {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBdct_flow:(BDCTFlow *)bdct_flow {
    objc_setAssociatedObject(self, @selector(bdct_flow), bdct_flow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface BDCTFlowPerformance ()

@property (nonatomic, assign) CFTimeInterval startTimeStamp;

@property (nonatomic, strong, readwrite) NSMutableDictionary *timeStampParams;

@end


@implementation BDCTFlowPerformance

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeStampParams = [NSMutableDictionary dictionary];
        _startTimeStamp = BDCTTimestamp;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSString *key = [BDMappingStrategy mapCamelToSnakeCase:NSStringFromSelector([anInvocation selector])];
    if ([_timeStampParams btd_objectForKey:key default:nil] == nil) {
        if ([key isEqualToString:@"face_detect_open"] || [key isEqualToString:@"flow_start"]) {
            _timeStampParams[key] = @((long long)[[NSDate date] timeIntervalSince1970] * 1000);
        } else {
            _timeStampParams[key] = @((int)(BDCTTimestamp - _startTimeStamp));
        }
    }
}

@end


@interface BDCTFlow ()

@property (nonatomic, strong, readwrite) BDCTFlowContext *context;
@property (nonatomic, strong, readwrite) BDCTAPIService *apiService;
@property (nonatomic, strong, readwrite) BDCTEventTracker *eventTracker;
@property (nonatomic, strong, readwrite) BDCTFlowPerformance *performance;

@property (nonatomic, weak) UINavigationController *rootNavigationController;

@end


@implementation BDCTFlow

+ (instancetype)flowWithContext:(BDCTFlowContext *)context {
    return [[BDCTFlow alloc] initWithContext:context];
}

- (instancetype)initWithContext:(BDCTFlowContext *)context {
    self = [super init];
    if (self) {
        _context = context;
        _performance = [BDCTFlowPerformance new];
        _performance.flow = self;
        if (BytedCertManager.shareInstance.uiConfigBlock != nil) {
            BytedCertManager.shareInstance.uiConfigBlock([BytedCertUIConfigMaker new]);
        }
    }
    return self;
}

- (BDCTAPIService *)apiService {
    if (!_apiService) {
        _apiService = [[BDCTAPIService alloc] initWithContext:self.context];
    }
    return _apiService;
}

- (BDCTEventTracker *)eventTracker {
    if (!_eventTracker) {
        _eventTracker = [BDCTEventTracker new];
        _eventTracker.context = self.context;
        _eventTracker.bdct_flow = self;
    }
    return _eventTracker;
}

- (void)showViewController:(UIViewController *)viewController {
    viewController.hidesBottomBarWhenPushed = YES;
    if (self.rootNavigationController) {
        [self.rootNavigationController pushViewController:viewController animated:YES];
        return;
    }

    if (!_fromViewController) {
        self.fromViewController = [UIViewController bdct_topViewController];
    }
    BDAssert(_fromViewController != nil, @"Fail to find a view controller to show the new view controller");

    BOOL forcePresent = _forcePresent;
    UIWindow *fromWindow = _fromViewController.view.window;
    if (fromWindow.btd_width > fromWindow.btd_height) {
        forcePresent = YES;
    }
    if (!forcePresent && _fromViewController.navigationController) {
        if ([_fromViewController.navigationController isKindOfClass:NSClassFromString(@"TTNavigationController")]) {
            viewController.automaticallyAdjustsScrollViewInsets = NO;
        }
        if (_disableInteractivePopGesture) {
            if ([[BytedCertInterface sharedInstance].bytedCertUIDelegate respondsToSelector:@selector(disablePanBackGuesture:)]) {
                [[BytedCertInterface sharedInstance].bytedCertUIDelegate disablePanBackGuesture:viewController];
            }
        }
        [_fromViewController.navigationController pushViewController:viewController animated:YES];
        self.rootNavigationController = _fromViewController.navigationController;
        return;
    }
    BDCTPortraitNavigationController *navigationController = [[BDCTPortraitNavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [navigationController setNavigationBarHidden:YES];
    [_fromViewController presentViewController:navigationController animated:YES completion:nil];
    self.rootNavigationController = navigationController;
}

@end
