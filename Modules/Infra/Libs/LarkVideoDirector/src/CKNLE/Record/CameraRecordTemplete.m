//
//  CameraRecordTemplete.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import "CameraRecordTemplete.h"
#import <CameraClient/ACCRecordGestureComponent.h>
#import <CameraClient/ACCRecordAuthComponent.h>
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import <CameraClient/ACCRecordSelectPropComponent.h>
#import <CameraClient/ACCRecordSwitchModeComponent.h>
#import <CameraClient/ACCPropComponentV2.h>
#import <CameraClient/ACCCaptureComponent.h>
#import <CameraClient/ACCSpeedControlComponent.h>
#import <CameraClient/ACCRecordFlowComponent.h>
#import <CameraClient/ACCRecordDeleteComponent.h>
#import <CameraClient/ACCRecordCompleteComponent.h>
#import <CameraClient/ACCRecordProgressComponent.h>
#import <CameraClient/ACCPropPickerComponent.h>
#import <CameraClient/ACCFocusComponent.h>
#import <CameraClient/ACCCameraSwapComponent.h>
#import <CameraClient/ACCFlashComponent.h>
#import <CameraClient/ACCBeautyComponentFlowPlugin.h>
#import <CameraClient/ACCBeautyComponentBarItemPlugin.h>
#import <CameraClient/ACCBeautyFeatureComponentTrackerPlugin.h>
#import <CameraClient/ACCFilterComponentTrackerPlugin.h>
#import <CameraClient/ACCFilterComponentDPlugin.h>
#import <CameraClient/ACCFilterComponentFlowPlugin.h>
#import <CameraClient/ACCFilterComponentGesturePlugin.h>
#import <CameraClient/ACCFilterComponentBeautyPlugin.h>
#import <CameraClient/ACCFilterComponentTipsPlugin.h>
#import <CameraClient/ACCRecordSplitTipComponent.h>
#import <CreationKitComponents/ACCBeautyPanelViewModel.h>
#import <CameraClient/ACCRecordSubmodeComponent.h>
#import <CameraClient/ACCLightningStyleRecordFlowComponent.h>
#import "MVPRecordCloseComponent.h"
#import "MVPCaptureOrientationComponent.h"
#import "LVDTimeCostComponent.h"
#import "MVPRecordSplitTipComponent.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation CameraRecordTemplete

- (nonnull NSArray<Class> *)componentClasses {
    NSMutableArray* componments = [[NSMutableArray alloc] init];
    [componments addObjectsFromArray:@[
                    [LVDTimeCostComponent class], // 耗时统计，放在首位精确统计
            //        [ACCRecordAuthComponent class], // 权限管理
                    [ACCCaptureComponent class], // 闪光灯、聚焦、曝光、手电筒
                    [ACCFocusComponent class],
                    [ACCCameraSwapComponent class],
                    [ACCFlashComponent class],
                    [MVPRecordCloseComponent class],
                    [ACCLightingStyleRecordFlowComponent class], // 拍摄流程
                    [ACCRecordDeleteComponent class], // 删除按钮
                    [ACCRecordCompleteComponent class], // 完成按钮
                    [ACCPropComponentV2 class], // 道具
                    [ACCRecordSubmodeComponent class],
                    [ACCRecordSwitchModeComponent class], // 底tab切换
                    [ACCFilterComponent class], // 滤镜
                    [ACCBeautyFeatureComponent class], // 美颜
                    [ACCRecordProgressComponent class], // 拍摄进度条
                    [ACCRecordGestureComponent class],// 手势管理组件
                    // MVP
                    [MVPCaptureOrientationComponent class],
    ]];

    if (![LVDCameraConfig supportMultitaskingCameraAccess]) {
        [componments addObject:[MVPRecordSplitTipComponent class]];
    }

    return componments;
}

- (NSArray<ACCFeatureComponentPluginClass> *)componentPluginClasses {
    return @[
        [ACCBeautyComponentBarItemPlugin class],
        [ACCBeautyFeatureComponentTrackerPlugin class],
        [ACCBeautyComponentFlowPlugin class],
        [ACCFilterComponentBeautyPlugin class],
        [ACCFilterComponentTrackerPlugin class],
        [ACCFilterComponentGesturePlugin class],
        [ACCFilterComponentFlowPlugin class],
        [ACCFilterComponentDPlugin class],
        [ACCFilterComponentTipsPlugin class],
        [LarkRecordSwitchModePlugin class],
        [LarkCameraServicePlugin class],
        [LarkRecordDeletePlugin class],
        [LarkRecordCompletePlugin class],
        [LarkFilterPlugin class],
        [LarkBeautyFeaturePlugin class],
    ];
}

@end
