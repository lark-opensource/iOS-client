//
//  OPAppVersionType.m
//  OPSDK
//
//  Created by yinyuan on 2020/12/16.
//

#import "OPAppVersionType.h"

NSString * _Nonnull OPAppVersionTypeToString(OPAppVersionType versionType) {
    switch (versionType) {
        case OPAppVersionTypePreview:
            return @"preview";
        default:
            return @"current";
    }
}

OPAppVersionType OPAppVersionTypeFromString(NSString * _Nullable versionTypeString) {
    if ([versionTypeString isEqualToString:OPAppVersionTypeToString(OPAppVersionTypePreview)]) {
        return OPAppVersionTypePreview;
    } else {
        return OPAppVersionTypeCurrent;
    }
}
