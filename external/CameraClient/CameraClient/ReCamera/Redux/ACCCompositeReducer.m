//
//  ACCCompositeReducer.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCCompositeReducer.h"
#import "ACCAction.h"
#import "ACCState.h"

@interface ACCCompositeReducer ()
@property (nonatomic, strong, readwrite) NSDictionary *reducersMap;
@end

@implementation ACCCompositeReducer
+ (ACCCompositeReducer *)reducerWithReducers:(NSDictionary *)reducers
{
    ACCCompositeReducer *reducer = [[self alloc] init];
    reducer.reducersMap = [reducers copy];
    return reducer;
}

- (id<ACCCompositeState>)stateWithAction:(ACCAction *)action andState:(id<ACCCompositeState>)state
{
    
    NSDictionary *reducers = self.reducersMap;
    
    NSMutableDictionary *stateTree = [NSMutableDictionary dictionary];
    BOOL hasChanges = NO;
    for (id aKey in reducers) {
        ACCReducer *theReducer = [reducers objectForKey:aKey];
        NSAssert(theReducer != nil, @"cannot find reducer for keypath: %@", [aKey debugDescription]);
        
        id previousChildState = state[aKey];
        
        if (theReducer.domainActionClass != NULL && ![action isKindOfClass:[theReducer domainActionClass]]) {
            if (previousChildState != nil) {
                [stateTree setObject:previousChildState forKey:aKey];
            }
        } else {
            id childState = [theReducer stateWithAction:action andState:previousChildState];
            if (!hasChanges && previousChildState != childState) {
                hasChanges = YES;
            }
            
            if (childState) {
                [stateTree setObject:childState forKey:aKey];
            }
        }
    }
    if (hasChanges) {
        return [[state class] createStateWithDictionary:stateTree];
    } else {
        return state;
    }
}
@end
