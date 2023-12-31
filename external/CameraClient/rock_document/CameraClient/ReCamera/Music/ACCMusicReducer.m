//
//  ACCMusicReducer.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/31.
//

#import "ACCMusicReducer.h"
#import "ACCMusicState.h"
#import "ACCMusicAction.h"

@implementation ACCMusicReducer

- (ACCMusicState *)stateWithAction:(ACCMusicAction *)action andState:(ACCMusicState *)state {
    BOOL isDomainClass= [state isKindOfClass:[ACCMusicState class]] && [action isKindOfClass:[ACCMusicAction class]];
    if (!isDomainClass) {
        NSAssert(NO, @"invalid state type");
        return state;
    }
    
    ACCMusicState *updatedState = [[ACCMusicState alloc] init];
    [updatedState mergeValuesForKeysFromModel:state];
    updatedState.isOpen = action.isOpen;
    
    return updatedState;
}

- (Class)domainActionClass {
    return [ACCMusicAction class];
}
@end
