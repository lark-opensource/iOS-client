//
//  ACCServiceLocator.m
//  CameraClient
//
// Created by Hao Yipeng on April 27, 2020
//

#import "ACCServiceLocator.h"

IESContainer* __attribute__((weak)) ACCBaseContainer()
{
    // Caution: Should provide your own implementation!
    assert(NO);
    return nil;
}

IESServiceProvider* __attribute__((weak)) ACCBaseServiceProvider()
{
    // Caution: Should provide your own implementation!
    assert(NO);
    return nil;
}
