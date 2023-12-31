//
//  ACCEditVideoBeautyUIConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/2.
//

#import "ACCEditVideoBeautyUIConfig.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCEditVideoBeautyUIConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentCollectionViewTopOffset = 36.f;
        self.tbSelectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
        self.tbSelectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        self.tbUnselectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightRegular];
        self.tbUnselectedTitleColor = [ACCResourceColor(ACCUIColorConstTextInverse2) colorWithAlphaComponent:0.5];
        ACCBeautyHeaderViewStyle headerStyle = ACCBeautyHeaderViewStyleDefault;
        ACCEditViewUIOptimizationType UIOptimizationType = ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType);
        switch (UIOptimizationType) {
            case ACCEditViewUIOptimizationTypeDisabled: {
                headerStyle = ACCBeautyHeaderViewStyleDefault;
                break;
            }
            case ACCEditViewUIOptimizationTypeSaveCancelBtn: {
                headerStyle = ACCBeautyHeaderViewStyleSaveCancelBtn;
                break;
            }
            case ACCEditViewUIOptimizationTypePlayBtn: {
                headerStyle = ACCBeautyHeaderViewStylePlayBtn;
                break;
            }
            case ACCEditViewUIOptimizationTypeReplaceIconWithText: {
                headerStyle = ACCBeautyHeaderViewStyleReplaceIconWithText;
                break;
            }
        }
        self.headerStyle = headerStyle;
    }
    return self;
}

@end
