//
//  CJPayLynxCardManagerV2.m
//  Aweme
//
//  Created by wangxiaohong on 2023/3/1.
//

#import "CJPayLynxViewManager.h"

#import "CJPayLynxViewPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "UIView+CJPay.h"
#import "CJPayLynxViewContext.h"

#import <Puzzle/IESHYHybridContainerConfig.h>
#import <Puzzle/PuzzleContext.h>
#import <Puzzle/PuzzleHybridContainer.h>
#import <BDXBridgeKit/BDXBridgeEventSubscriber.h>
#import <BDXBridgeKit/BDXBridgeEventCenter.h>
#import <BDXBridgeKit/BDXBridgeEvent.h>

#import "CJPayUIMacro.h"

static NSString *kCJPayLynxViewEventName = @"cjpay_lynxcard_common_event";
static NSString *kCJPayLynxViewNativeEventName = @"cjpay_lynxcard_common_event_from_native";
static NSString *kCJPayLynxViewEventKey = @"cjpay_event_name";

@interface CJPayLynxViewManager()<CJPayLynxViewPlugin>

@property (nonatomic, strong) NSMutableArray<CJPayLynxViewContext *> *containersArray;//lynx card管理
//事件订阅通知
@property (nonatomic, strong) BDXBridgeEventSubscriber *lynxViewEventSubscriber;

@end

@implementation CJPayLynxViewManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayLynxViewPlugin)
})

+ (instancetype)defaultService {
    static CJPayLynxViewManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayLynxViewManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _containersArray = [NSMutableArray array];
        [self p_setupSubscribeEvent];
    }
    return self;
}

- (BOOL)pluginHasInstalled {
    return YES;
}

- (UIView *)createLynxCardWithScheme:(NSString *)scheme frame:(CGRect)frame initialDataStr:(NSString *)dataStr delegate:(nullable id<CJPayLynxViewDelegate>)delegate {
    IESHYHybridContainerConfig *config = [IESHYHybridContainerConfig hybridContainerConfigWithSchema:scheme preferredFrame:frame];
    config.hideLoading = YES;
    config.showErrorView = NO;
    PuzzleContext *context = [[PuzzleContext alloc] init];
    context.initialData = @{
        @"cj_initial_props": @{
            @"cj_sdk_version" : [CJSDKParamConfig defaultConfig].settingsVersion,
            @"cj_version" : @"1",
            @"cj_timestamp" : @([[NSDate date] timeIntervalSince1970] * 1000),
            @"cj_data" : CJString(dataStr)
        }
    };
    context.customGlobalProps = @{};
    
    CJPayLynxViewContext *lynxContext = [CJPayLynxViewContext new];
    PuzzleHybridContainer *lynxCardView = [[PuzzleHybridContainer alloc] initWithConfiguration:config context:context lifeCycleDelegate:lynxContext];
    
    lynxContext.lynxCardView = lynxCardView;
    lynxContext.delegate = delegate;
    [self.containersArray addObject:lynxContext];
    
    return lynxCardView;
}

- (void)loadLynxView:(UIView *)view {
    if (![self p_isHybridView:view]) {
        CJPayLogInfo(@"LynxView类型错误%@", NSStringFromClass(view.class));
        return;
    }
    PuzzleHybridContainer *hybridContainer = (PuzzleHybridContainer *)view;
    [hybridContainer load];
}

- (void)publishEvent:(NSString *)event data:(NSDictionary *)params {
    NSMutableDictionary *data = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    [data cj_setObject:CJString(event) forKey:kCJPayLynxViewEventKey];
    BDXBridgeEvent *bridgeEvent = [BDXBridgeEvent eventWithEventName:kCJPayLynxViewNativeEventName params:[data copy]];
    [BDXBridgeEventCenter.sharedCenter publishEvent:bridgeEvent];
    [CJTracker event:@"wallet_rd_cashier_info" params:@{
        @"from" : @"native_cashier_card_sendEvent",
        @"detailInfo": CJString([data cj_toStr])
    }];
}

- (NSString *)getContainerIdWithView:(UIView *)view {
    if (![self p_isHybridView:view]) {
        return @"";
    }
    PuzzleHybridContainer *hybridContainer = (PuzzleHybridContainer *)view;
    return hybridContainer.kitView.containerID;
}

- (BOOL)p_isHybridView:(UIView *)view {
    return [view isKindOfClass:PuzzleHybridContainer.class];
}

- (void)p_setupSubscribeEvent {
    @CJWeakify(self)
    self.lynxViewEventSubscriber = [BDXBridgeEventSubscriber subscriberWithCallback:^(NSString * _Nonnull eventName, NSDictionary * _Nullable params) {
        @CJStrongify(self)
        [CJTracker event:@"wallet_rd_cashier_info" params:@{
            @"from" : @"native_cashier_card_reciveEvent",
            @"detailInfo": CJString([params cj_toStr])
        }];
        if ([eventName isEqualToString:kCJPayLynxViewEventName]) {
            NSString *containerId = [params cj_stringValueForKey:@"container_id"];
            if (!Check_ValidString(containerId)) {
                [CJTracker event:@"wallet_rd_get_lynx_event_exception" params:@{
                    @"reason" : @"containerId参数异常",
                    @"eventName" : CJString(eventName)
                }];
            }
            [self.containersArray enumerateObjectsUsingBlock:^(CJPayLynxViewContext * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.lynxCardView.kitView.containerID isEqualToString:containerId] && [obj.delegate respondsToSelector:@selector(lynxView:receiveEvent:withData:)]) {
                    [obj.delegate lynxView:obj.lynxCardView receiveEvent:[params cj_stringValueForKey:kCJPayLynxViewEventKey] withData:params];
                }
            }];
        } else {
            [CJTracker event:@"wallet_rd_get_lynx_event_exception" params:@{
                @"eventName" : CJString(eventName)
            }];
        }
    }];
    
    [[BDXBridgeEventCenter sharedCenter] subscribeEventNamed:kCJPayLynxViewEventName withSubscriber:self.lynxViewEventSubscriber];
}

@end
