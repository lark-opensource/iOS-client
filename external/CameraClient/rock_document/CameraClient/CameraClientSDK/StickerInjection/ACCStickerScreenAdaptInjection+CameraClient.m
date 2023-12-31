//
//  ACCStickerScreenAdaptInjection+CameraClient.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/16.
//

#import "ACCStickerScreenAdaptInjection+CameraClient.h"
#import "AWEXScreenAdaptManager.h"

@implementation ACCStickerScreenAdaptInjection (CameraClient)

+ (BOOL)needAdaptScreen
{
    return [AWEXScreenAdaptManager needAdaptScreen];
}

+ (CGRect)standPlayerFrame;
{
    return [AWEXScreenAdaptManager standPlayerFrame];
}

@end
