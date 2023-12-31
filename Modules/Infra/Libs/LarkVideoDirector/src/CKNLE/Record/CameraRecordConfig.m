//
//  CameraRecordConfig.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import "CameraRecordConfig.h"
#import "CameraRecordRouter.h"
#import "CameraRecordTemplete.h"
#import "MODMVPRecorderServiceContainer.h"

@interface CameraRecordConfig ()
@property (nonatomic, strong) id<ACCBusinessTemplate> businessTemplate;
@property (nonatomic, strong) id<ACCRouterCoordinatorProtocol> routerCoordinator;
@property (nonatomic, strong) ACCRecordViewControllerInputData* input;
@end

@implementation CameraRecordConfig

@synthesize inputData;

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    self = [super init];
    if (self) {
        self.inputData = inputData;
        self.businessTemplate = [[CameraRecordTemplete alloc] init];
        self.routerCoordinator = [[CameraRecordRouter alloc] init];
    }
    return self;
}

- (id<ACCBusinessTemplate>)businessTemplate
{
    return _businessTemplate;
}

- (id<ACCRouterCoordinatorProtocol>)routerCoordinator
{
    return _routerCoordinator;
}

- (id<IESServiceRegister,IESServiceProvider>)businessServiceContainerWithSessionContainer:(id<IESServiceRegister,IESServiceProvider>)sessionContainer
{
    return [[MODMVPRecorderServiceContainer alloc] initWithParentContainer:sessionContainer];
}

@end
