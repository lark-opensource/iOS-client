//
//  MVPBaseServiceContainer.m
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import "MVPBaseServiceContainer.h"
#import <CreationKitComponents/ACCFilterDefines.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CameraClient/ACCCameraControlWrapper.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import <CameraClient/ACCRecordViewController.h>
#import "CameraRecordController.h"
#import "NLEEditorManager.h"

@implementation MVPBaseServiceContainer

+ (instancetype)sharedContainer
{
    static dispatch_once_t onceToken;
    static MVPBaseServiceContainer *baseServiceContainer = nil;
    dispatch_once(&onceToken, ^{
        baseServiceContainer = [[self alloc] init];
    });
    return baseServiceContainer;
}

- (void)barItemContainer:(id<ACCBarItemContainerView>)barItemContainer
       didClickedBarItem:(void *)itemId {
    if (itemId == ACCRecorderToolBarModernBeautyContext) {
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"beauty", @"target": @"public_photograph_beauty_edit_view"}];
        [LVDCameraMonitor customTrack:@"public_photograph_beauty_edit_view" params:@{}];
    } else if (itemId == ACCRecorderToolBarFilterContext) {
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"filter", @"target": @"public_photograph_filter_edit_view"}];
        [LVDCameraMonitor customTrack:@"public_photograph_filter_edit_view" params:@{}];
    } else if (itemId == ACCRecorderToolBarSwapContext) {
        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{@"click": @"flip"}];
    } else if (itemId == ACCRecorderToolBarFlashContext) {
        id<ACCCameraControlProtocol> cameraControl = IESAutoInline(((ACCRecordViewController*)self.camera).serviveProvider , ACCCameraControlProtocol);
        NSString* flashMode = @"";

        if ([LVDCameraMonitor getTabisPhoto]) {
            if (cameraControl.flashMode == ACCCameraFlashModeOff) {
                flashMode = @"close";
            } else if (cameraControl.flashMode == ACCCameraFlashModeOn) {
                flashMode = @"open";
            } else if (cameraControl.flashMode == ACCCameraFlashModeAuto) {
                flashMode = @"auto";
            }
        } else {
            if (cameraControl.torchMode == ACCCameraTorchModeOff) {
                flashMode = @"close";
            } else if (cameraControl.torchMode == ACCCameraTorchModeOn) {
                flashMode = @"open";
            } else if (cameraControl.torchMode == ACCCameraTorchModeAuto) {
                flashMode = @"auto";
            }
        }

        [LVDCameraMonitor customTrack:@"public_photograph_click" params:@{
            @"click": @"flash",
            @"status": flashMode
        }];
    }
}

- (void)clickSendBtn:(UIControl *)sender {
    [NLEEditorManager sendVideo:self sender: sender];
}

@end

IESContainer* ACCBaseContainer() {
    return [MVPBaseServiceContainer sharedContainer];
}

IESServiceProvider* ACCBaseServiceProvider()
{
    static IESServiceProvider *baseProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseProvider = [[IESServiceProvider alloc] initWithContainer:ACCBaseContainer()];
        
    });
    return baseProvider;
}
