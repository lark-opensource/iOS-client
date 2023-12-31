//
//  ACCThunkAction.m
//  CameraClient
//
//  Created by Liu Deping on 2020/1/5.
//

#import "ACCThunkAction.h"

@interface ACCThunkAction ()

@property (nonatomic, copy) ACCThunkBody thunkBody;

@end

@implementation ACCThunkAction

- (instancetype)initWithThunkBody:(ACCThunkBody)thunkBody
{
    if (self = [super init]) {
        self.thunkBody = thunkBody;
    }
    return self;
}

@end
