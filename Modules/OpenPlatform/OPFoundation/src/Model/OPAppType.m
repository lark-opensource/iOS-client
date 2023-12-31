//
//  OPAppType.m
//  OPSDK
//
//  Created by yinyuan on 2020/12/16.
//

#import "OPAppType.h"

NSString * _Nonnull OPAppTypeToString(OPAppType appType) {
    switch (appType) {
        case OPAppTypeGadget:
            return @"gadget";
        case OPAppTypeWebApp:
            return @"webApp";
        case OPAppTypeWidget:
            return @"widget";
        case OPAppTypeBlock:
            return @"block";
        case OPAppTypeThirdNativeApp:
            return @"thirdNativeApp";
        case OPAppTypeDynamicComponent:
            return @"dynamicComponent";
        case OPAppTypeSDKMsgCard:
            return @"msgCardTemplate";
        default:
            return @"unknown";;
    }
}

OPAppType OPAppTypeFromString(NSString * _Nullable appTypeString) {
    if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeGadget)]) {
        return OPAppTypeGadget;
    } else if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeWebApp)]) {
        return OPAppTypeWebApp;
    } else if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeWidget)]) {
        return OPAppTypeWidget;
    } else if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeBlock)]) {
        return OPAppTypeBlock;
    } else if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeDynamicComponent)]) {
        return OPAppTypeDynamicComponent;
    } else if ([appTypeString isEqualToString:OPAppTypeToString(OPAppTypeSDKMsgCard)]) {
        return OPAppTypeSDKMsgCard;
    } else {
        return OPAppTypeUnknown;
    }
}
