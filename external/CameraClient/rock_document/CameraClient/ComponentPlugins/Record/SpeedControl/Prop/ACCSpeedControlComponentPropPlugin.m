//
//  ACCSpeedControlComponentPropPlugin.m
//  Indexer
//
//  Created by bytedance on 2021/10/28.
//

#import "ACCSpeedControlComponentPropPlugin.h"

#import "ACCSpeedControlComponent.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordPropService.h"
#import "ACCRecordFlowService.h"
#import "ACCFlowerService.h"
#import "ACCFlowerPanelEffectListModel.h"

@interface ACCSpeedControlComponentPropPlugin () <ACCRecordPropServiceSubscriber, ACCFlowerServiceSubscriber>

@property (nonatomic, weak, readonly) ACCSpeedControlComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;

@end

@implementation ACCSpeedControlComponentPropPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)

+(id)hostIdentifier
{
    return [ACCSpeedControlComponent class];
}

- (void)bindServices:(nonnull id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    self.flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    self.propService = IESAutoInline(serviceProvider, ACCRecordPropService);
    [self.propService addSubscriber:self];
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
    [self.hostComponent.viewModel addShouldShowPrediacte:^BOOL{
        IESEffectModel *prop = self.propService.prop;
        return ![prop isTypeAudioGraph] && self.flowerService.currentItem.dType != ACCFlowerEffectTypeScan;
    } forHost:self];
    
    [self.hostComponent.viewModel.barItemShowPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        IESEffectModel *prop = self.propService.prop;
        return ![prop isTypeAudioGraph] && self.flowerService.currentItem.dType != ACCFlowerEffectTypeScan;
    } with:self];
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    if ([prop isTypeAudioGraph]) {
        [self.hostComponent externalSelectSpeed:HTSVideoSpeedNormal];
    }
    [self.hostComponent showSpeedControlIfNeeded];
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSpeedControlContext];
}

- (void)flowerServiceDidChangeFromItem:(ACCFlowerPanelEffectModel *)prevItem toItem:(ACCFlowerPanelEffectModel *)item
{
    // 切换到扫一扫道具，隐藏UI即可，没必要恢复 HTSVideoSpeedNormal，因为扫一扫模式不支持拍摄。
    [self.hostComponent showSpeedControlIfNeeded];
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSpeedControlContext];
}

#pragma mark - Properties

- (ACCSpeedControlComponent *)hostComponent
{
    return self.component;
}

@end
