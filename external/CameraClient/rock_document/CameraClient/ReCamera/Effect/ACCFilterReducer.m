//
//  ACCFilterReducer.m
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import "ACCFilterReducer.h"
#import "ACCFilterAction.h"
#import "ACCFilterState.h"

@implementation ACCFilterReducer

- (Class)domainActionClass
{
    return [ACCFilterAction class];
}

- (id)stateWithAction:(ACCFilterAction *)action andState:(id)state
{
    NSAssert([state isKindOfClass:[ACCFilterState class]], @"invalid state type");
    if (![action isKindOfClass:[ACCFilterAction class]]) {
        return state;
    }
    if (action.status == ACCActionStatusSucceeded) {
        ACCFilterState *updatedState = [[ACCFilterState alloc] init];
        [updatedState mergeValuesForKeysFromModel:state];
        switch (action.type) {
            case ACCFilterActionTypeApplyFilter: {
                updatedState.filterModel = action.filterModel;
                break;
            }
            case ACCFilterActionTypeSwitchingFilter: {
                
                break;
            }
            default:
                break;
        }
        return updatedState;
    }
    return state;
}

@end
