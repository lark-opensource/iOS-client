//
//  BDXVideoManager+Aweme.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/29.
//

#import "BDXVideoManager+Aweme.h"
#import "BDXAwemeVideoCore.h"
#import "BDXVideoViewController.h"

@interface BDXVideoModelAwemeConverter ()

@end

@implementation BDXVideoModelAwemeConverter


@end

@implementation BDXVideoManager (Aweme)

+ (void)initialize
{
    if (self == [BDXVideoManager class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            BDXVideoManager.videoModelConverterClz = [BDXVideoModelAwemeConverter class];
            BDXVideoManager.videoCorePlayerClazz = [BDXAwemeVideoCore class];
            BDXVideoManager.fullScreenPlayerClz = [BDXVideoViewController class];
        });
    }
}

@end
