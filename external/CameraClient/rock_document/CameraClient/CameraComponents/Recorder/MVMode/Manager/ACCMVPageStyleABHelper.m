//
//  ACCMVPageStyleABHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/8.
//

#import "ACCMVPageStyleABHelper.h"
#import "ACCConfigKeyDefines.h"

@implementation ACCMVPageStyleABHelper

#pragma mark - cutsame text

+ (NSString *)acc_cutsameNameText
{
    ACCCutsameNameTextType nameType = ACCConfigInt(kConfigInt_replace_cutsame_name_text);
    switch (nameType) {
        case ACCCutsameNameTextTypeDefault:
            return @"影集";
            break;
        case ACCCutsameNameTextTypeA:
            return @"模板";
            break;
        case ACCCutsameNameTextTypeB:
            return @"剪同款";
            break;
    }
}

+ (NSString *)acc_cutsameTitleText
{
    ACCCutsameNameTextType nameType = ACCConfigInt(kConfigInt_replace_cutsame_name_text);
    switch (nameType) {
        case ACCCutsameNameTextTypeDefault:
            return @"影集模板";
            break;
        case ACCCutsameNameTextTypeA:
            return @"模板";
            break;
        case ACCCutsameNameTextTypeB:
            return @"模板";
            break;
    }
}

+ (NSString *)acc_cutsameSelectHintText
{
    ACCCutsameSelectHintType hintType = ACCConfigInt(kConfigInt_replace_cutsame_select_hint_text);
    switch (hintType) {
        case ACCCutsameSelectHintTypeDefault:
            return @"选择素材";
            break;
        case ACCCutsameSelectHintTypeA:
            return @"使用";
            break;
        case ACCCutsameSelectHintTypeB:
            return @"选择照片";
            break;
        case ACCCutsameSelectHintTypeC:
            return @"生成视频";
            break;
    }
}

@end
