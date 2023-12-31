//
//  BDXVideoManager+Toutiao.m
//  TTLynxAdapter
//
//  Created by jiayuzun on 2020/9/28.
//

#import "BDXVideoManager+Toutiao.h"
#import "BDXToutiaoVideoCore.h"
#import "BDXVideoModelToutiaoConverter.h"
#import "BDXToutiaoVideoViewController.h"

@implementation BDXVideoManager (Toutiao)

+ (void)initialize
{
    if (self == [BDXVideoManager class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            BDXVideoManager.videoModelConverterClz = [BDXVideoModelToutiaoConverter class];
            BDXVideoManager.videoCorePlayerClazz = [BDXToutiaoVideoCore class];
//            BDXVideoManager.fullScreenPlayerClz = [BDXToutiaoVideoViewController class];
        });
    }
}

@end
