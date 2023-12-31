//
//  BDXVideoManager.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import "BDXVideoManager.h"

@implementation BDXVideoManager

static Class s_videoCorePlayerClz;
static Class s_videoModelConverterClz;
static Class s_fullScreenPlayerClz;
static id<BDXVideoManagerDelegate> s_delegate;

+ (void)setVideoCorePlayerClazz:(Class)videoCorePlayerClazz
{
    s_videoCorePlayerClz = videoCorePlayerClazz;
}

+ (Class)videoCorePlayerClazz
{
    return s_videoCorePlayerClz;
}

+ (void)setVideoModelConverterClz:(Class)videoModelConverterClz
{
    s_videoModelConverterClz = videoModelConverterClz;
}

+ (Class)videoModelConverterClz
{
    return s_videoModelConverterClz;
}

+ (void)setFullScreenPlayerClz:(Class)fullScreenPlayerClz
{
    s_fullScreenPlayerClz = fullScreenPlayerClz;
}

+ (Class)fullScreenPlayerClz
{
    return s_fullScreenPlayerClz;
}

+ (void)setDelegate:(id<BDXVideoManagerDelegate>)delegate
{
    s_delegate = delegate;
}

+ (id<BDXVideoManagerDelegate>)delegate
{
    return s_delegate;
}

@end
