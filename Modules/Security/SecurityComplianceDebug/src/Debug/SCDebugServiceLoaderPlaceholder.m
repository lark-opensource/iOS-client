//
//  SCDebugServiceLoader+Extension.m
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/8.
//

#import "SCDebugServiceLoaderPlaceholder.h"
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation SCDebugServiceLoaderPlaceholder

@end


LoadableDidFinishLaunchFuncBegin(debugService)

if ([NSObject respondsToSelector:@selector(startConfigDebugServiceLoader)]) {
    [NSObject performSelector:@selector(startConfigDebugServiceLoader)];
}

LoadableDidFinishLaunchFuncEnd(debugService)
