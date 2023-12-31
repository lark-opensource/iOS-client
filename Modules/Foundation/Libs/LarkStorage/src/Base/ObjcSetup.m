//
//  ObjcSetup.m
//  LarkStorage
//
//  Created by 7Up on 2023/9/5.
//

#import "ObjcSetup.h"
#import <LKLoadable/Loadable.h>
#import <LarkStorageCore/LarkStorageCore-Swift.h>
#import <LarkStorage/LarkStorage-Swift.h>

@implementation LarkStorageObjcSetup

@end

LoadableMainFuncBegin(LarkStorageObjcSetup)
[ObjcDependency setLoadOnce: ^(NSString * _Nonnull key) {
    [LarkStorageLoadable startByKey: key];
}];
LoadableMainFuncEnd(LarkStorageObjcSetup)
