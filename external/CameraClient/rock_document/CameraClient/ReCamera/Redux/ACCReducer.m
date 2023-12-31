//
//  ACCReducer.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCReducer.h"
#import "ACCState.h"
#import "ACCReducer.h"

@implementation ACCReducer
+ (instancetype)reducer
{
    return [[self alloc] init];
}

- (id)stateWithAction:(ACCAction *)action andState:(id)state
{
    // default implementation: do nothing
    return state;
}
@end


