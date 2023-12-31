//
//  ACCEditBarItemExtraData.m
//  CameraClient-Pods-Aweme
//
//  Created by wishes on 2020/6/2.
//

#import "ACCEditBarItemExtraData.h"

@implementation ACCEditBarItemExtraData

- (instancetype)initWithButtonClass:(nullable Class)buttonClass
                               type:(AWEEditAndPublishViewDataType)type {
    if (self = [super init]) {
        _buttonClass = buttonClass;
        _type = type;
    }
    return self;
}

@end
