//
//  BDXVideoManager+LV.m
//  Pods
//
//  Created by hanzheng on 2020/6/19.
//

#import "BDXVideoManager+LV.h"
#import "BDXLVVideoCore.h"

@implementation BDXVideoManager (LongVideo)

+ (void)initialize
{
    if (self == [BDXVideoManager class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
//            BDXVideoManager.videoModelConverterClz = [BDXVideoModelAwemeConverter class];
            BDXVideoManager.videoCorePlayerClazz = [BDXLVVideoCore class];
//            BDXVideoManager.fullScreenPlayerClz = [BDXVideoViewController class];
        });
    }
}

@end
