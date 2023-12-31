//
//  ACCRecordARComponent.m
//  Pods
//
//  Created by lixingpeng on 2019/8/5.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCRecordARComponent.h"
#import "ACCRecordARServiceImpl.h"
#import "AWEARTextInputViewController.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordFlowService.h"

@interface ACCRecordARComponent () <ACCRecordFlowServiceSubscriber>

@property (nonatomic, strong) AWEARTextInputViewController *arTextInputViewController;
@property (nonatomic, strong) ACCRecordARServiceImpl *arService;

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;

@end


@implementation ACCRecordARComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)

#pragma mark - Life Cycle

- (void)componentDidMount
{
    [self p_bindViewModel];
    ACCLog(@"componentDidMount");
}

- (void)componentWillAppear
{
    ACCLog(@"componentWillAppear");
}

- (void)componentDidAppear
{
    ACCLog(@"componentDidAppear");
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecordARService), self.arService);
}

#pragma mark - private methods

- (void)p_bindViewModel
{
    @weakify(self);
    [self.arService.dismissARInputSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self dismissARTextInputViewController];
    }];
    
    [self.arService.showARInputSignal.deliverOnMainThread subscribeNext:^(IESMMEffectMessage *x) {
        @strongify(self);
        [self showARTextInputViewControllerWithEffectMessageModel:x];
    }];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    [self.flowService addSubscriber:self];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState {
    if (ACCRecordFlowStateFinishExport == state) {
        [self dismissARTextInputViewController];
    }
}

#pragma mark - getter

- (UIViewController *)rootVC {
    if ([self.controller isKindOfClass:UIViewController.class]) {
        return (UIViewController *)(self.controller);
    }
    NSAssert([self.controller isKindOfClass:UIViewController.class], @"controller should be vc");
    return nil;
}

- (AWEARTextInputViewController *)arTextInputViewController
{
    if (!_arTextInputViewController) {
        _arTextInputViewController = [[AWEARTextInputViewController alloc] init];
        @weakify(self);
        _arTextInputViewController.textChangedBlock = ^(NSString * _Nonnull text, IESMMEffectMessage *messageModel) {
            @strongify(self)
            [self.arService sendSignalWhenInputTextChanged:text message:messageModel];
        };
        _arTextInputViewController.completionBlock = ^(BOOL confirmTextInput){
            @strongify(self)
            [self.viewContainer showItems:YES animated:YES];
            [self.arService sendSignalWhenInputComplete:confirmTextInput];
        };
    }
    return _arTextInputViewController;
}

- (ACCRecordARServiceImpl *)arService
{
    if (!_arService) {
        _arService = [[ACCRecordARServiceImpl alloc] init];
    }
    return _arService;
}

#pragma mark - AR功能

- (NSInteger)extracted {
    return [self.cameraService.effect effectTextLimit];
}

- (void)showARTextInputViewControllerWithEffectMessageModel:(IESMMEffectMessage *)effectMessageModel
{
    self.arTextInputViewController.effectMessageModel = effectMessageModel;
    self.arTextInputViewController.maxTextCount = [self extracted];
    [self.arTextInputViewController refreshTextStateWithEffectMessageModel:effectMessageModel];
    [self.rootVC addChildViewController:self.arTextInputViewController];
    [self.arTextInputViewController didMoveToParentViewController:self.rootVC];
    [self.rootVC.view addSubview:self.arTextInputViewController.view];
    ACCMasMaker(self.arTextInputViewController.view, {
        make.edges.equalTo(self.rootVC.view);
    });
    
    [self.viewContainer showItems:NO animated:YES];
}

- (void)dismissARTextInputViewController
{
    for (UIViewController *subViewController in self.rootVC.childViewControllers) {
        if (![subViewController isKindOfClass:[AWEARTextInputViewController class]]) {
            continue;
        }
        if ([subViewController isKindOfClass:[AWEARTextInputViewController class]]) {
            [(AWEARTextInputViewController *)subViewController dismiss];
            break;
        }
    }
}

@end


