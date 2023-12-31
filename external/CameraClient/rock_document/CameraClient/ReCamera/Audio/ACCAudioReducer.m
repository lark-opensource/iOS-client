//
//  ACCAudioReducer.m
//  CameraClient
//
//  Created by ZhangYuanming on 2020/1/8.
//

#import "ACCAudioReducer.h"
#import "ACCAudioState.h"
#import "ACCAudioAction.h"

@implementation ACCAudioReducer

- (ACCAudioState *)stateWithAction:(ACCAudioAction *)action andState:(ACCAudioState *)state {
    BOOL isDomainClass= [state isKindOfClass:[ACCAudioState class]] && [action isKindOfClass:[ACCAudioAction class]];
    if (!isDomainClass) {
        NSAssert(NO, @"invalid state type");
        return state;
    }
    
    ACCAudioState *updatedState = [[ACCAudioState alloc] init];
    [updatedState mergeValuesForKeysFromModel:state];
//    updatedState.isOpen = action.isOpen;
    
    return updatedState;
}

- (Class)domainActionClass {
    return [ACCAudioAction class];
}

@end
