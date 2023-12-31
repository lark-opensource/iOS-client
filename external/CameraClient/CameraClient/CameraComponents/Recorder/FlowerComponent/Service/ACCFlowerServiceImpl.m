//
//  ACCFlowerServiceImpl.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import "ACCFlowerServiceImpl.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordPropService.h"
#import "ACCFlowerPanelEffectListModel.h"

@interface ACCFlowerServiceImpl()

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, strong, readwrite) ACCFlowerPanelEffectModel *currentItem;

@end


@implementation ACCFlowerServiceImpl

@synthesize inputData = _inputData;
@synthesize inFlowerPropMode = _inFlowerPropMode;
@synthesize viewContainer = _viewContainer;
@synthesize isShowingPhotoProp = _isShowingPhotoProp;
@synthesize isCurrentScanProp = _isCurrentScanProp;

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    if (self = [super init]){
        _inputData = inputData;
    }
    return self;
}

- (void)setInFlowerPropMode:(BOOL)inFlowerPropMode
{
    _inFlowerPropMode = inFlowerPropMode;
    
    if (inFlowerPropMode) {
        [self.subscription performEventSelector:@selector(flowerServiceWillEnterFlowerMode:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
            [obj flowerServiceWillEnterFlowerMode:self];
        }];
        
        NSAssert(self.viewContainer != nil, @"");
        self.viewContainer.propPanelType = ACCRecordPropPanelFlower;
        [self.subscription performEventSelector:@selector(flowerServiceDidEnterFlowerMode:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
            [obj flowerServiceDidEnterFlowerMode:self];
        }];
    } else {
        self.viewContainer.propPanelType = ACCRecordPropPanelNone;
        [self.subscription performEventSelector:@selector(flowerServiceDidLeaveFlowerMode:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
            [obj flowerServiceDidLeaveFlowerMode:self];
        }];
    }
}

- (BOOL)JSBDidRequestApplyPropWithID:(NSString *)propID
{
    __block BOOL success = NO;
    [self.subscription performEventSelector:@selector(flowerService:JSBDidRequestApplyPropWithID:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
        if ([obj flowerService:self JSBDidRequestApplyPropWithID:propID]) {
            success = YES;
        }
    }];
    return success;
}

- (void)prefetchFlowerPanelData
{
    [self.subscription performEventSelector:@selector(flowerServiceDidReceivePrefetchRequest:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
        [obj flowerServiceDidReceivePrefetchRequest:self];
    }];
}

- (void)updateCurrentItem:(ACCFlowerPanelEffectModel *)item
{
    ACCFlowerPanelEffectModel *oldItem = _currentItem;
    _currentItem = item;
    [self.subscription performEventSelector:@selector(flowerServiceDidChangeFromItem:toItem:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
        [obj flowerServiceDidChangeFromItem:oldItem toItem:item];
    }];
}


@synthesize isShowingLynxWindow = _isShowingLynxWindow;

- (void)broadcastDidOpenTaskPanelMsg
{
    _isShowingLynxWindow = YES;
    [self.subscription performEventSelector:@selector(flowerServiceDidOpenTaskPanel:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
        [obj flowerServiceDidOpenTaskPanel:self];
    }];
}

- (void)broadcastDidCloseTaskPanelMsg
{
    _isShowingLynxWindow = NO;
    [self.subscription performEventSelector:@selector(flowerServiceDidCloseTaskPanel:) realPerformer:^(id<ACCFlowerServiceSubscriber> _Nonnull obj) {
        [obj flowerServiceDidCloseTaskPanel:self];
    }];
}

- (BOOL)isShowingPhotoProp
{
    if (self.inFlowerPropMode && self.currentItem.dType == ACCFlowerEffectTypePhoto) {
        return YES;
    }
    return NO;
}

- (BOOL)isCurrentScanProp
{
    if (self.inFlowerPropMode && self.currentItem.dType == ACCFlowerEffectTypeScan) {
        return YES;
    }
    return NO;
}


- (void)addSubscriber:(id<ACCFlowerServiceSubscriber>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

- (void)removeSubscriber:(id<ACCFlowerServiceSubscriber>)subscriber
{
    [self.subscription removeSubscriber:subscriber];
}

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}


@end
