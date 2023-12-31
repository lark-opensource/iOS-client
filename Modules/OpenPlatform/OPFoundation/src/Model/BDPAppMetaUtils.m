//
//  BDPAppMetaUtils.m
//  Timor
//
//  Created by lixiaorui on 2020/9/8.
//

#import "BDPAppMetaUtils.h"

@implementation BDPAppMetaUtils

+ (BOOL)metaIsDebugModeForVersionType:(OPAppVersionType)versionType {
    return versionType != OPAppVersionTypeCurrent;
}

+ (BOOL)metaIsReleaseCandidateModeForVersionType:(OPAppVersionType)versionType {
    return versionType == OPAppVersionTypeCurrent;
}

@end
