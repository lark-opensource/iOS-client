//
//  OPEnvTypeHelper.m
//  OPFoundation
//
//  Created by yinyuan on 2021/1/12.
//

#import "OPEnvTypeHelper.h"

NSString *OPEnvTypeToString(OPEnvType envType) {
    switch (envType) {
        case OPEnvTypeOnline:
            return @"online";
        case OPEnvTypeStaging:
            return @"staging";
        case OPEnvTypePreRelease:
            return @"pre_release";
        default:
            return @"unknown";
    }
}

@implementation OPEnvTypeHelper

static OPEnvType gEnvType = OPEnvTypeOnline;

+ (void)setEnvType:(OPEnvType)envType {
    gEnvType = envType;
}

+ (OPEnvType)envType {
    return gEnvType;
}

@end
