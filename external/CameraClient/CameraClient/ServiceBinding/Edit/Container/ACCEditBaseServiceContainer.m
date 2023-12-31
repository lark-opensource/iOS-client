//
//  ACCEditBaseServiceContainer.m
//  Pods
//
//  Created by xiangpeng on 2021/6/9.
//

#import "ACCEditBaseServiceContainer.h"
#import "ACCEditTransitionService.h"

#import <CreativeKit/ACCUIViewControllerProtocol.h>
#import <CreativeKit/ACCBusinessConfiguration.h>


@interface ACCEditBaseServiceContainer ()

@property (nonatomic, weak, readwrite) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak, readwrite) id<ACCUIViewControllerProtocol> viewController;

@end

@implementation ACCEditBaseServiceContainer

IESAutoInject(self, inputData, ACCBusinessInputData);
IESAutoInject(self, viewController, ACCUIViewControllerProtocol);

IESProvidesSingleton(ACCEditTransitionServiceProtocol)
{
    NSAssert(self.viewController != nil, @"ContainerViewController can not be nil");
    ACCEditTransitionService *transitionService = [[ACCEditTransitionService alloc] initWithContainerViewController:
                                                   (UIViewController<ACCEditTransitionContainerViewControllerProtocol> *)self.viewController];
    return transitionService;
}

@end
