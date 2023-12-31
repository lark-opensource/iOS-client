//
//  ACCThunkMiddleware.m
//  CameraClient
//
//  Created by Liu Deping on 2020/1/5.
//

#import "ACCThunkMiddleware.h"

@implementation ACCThunkMiddleware

- (ACCAction *)handleAction:(ACCAction *)action next:(ACCActionHandler)next __attribute__((annotate("csa_ignore_block_use_check")))
{
    if ([action isKindOfClass:[ACCThunkAction class]]) {
        ACCThunkAction *thunkAction = (ACCThunkAction *)action;
        thunkAction.thunkBody(self.dispatcher, self.stateGetter);
    } else {
        next(action);
        
    }
    return action;
}

@end
