//
//  ACCCreativeSession.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/8/19.
//

#import "ACCCreativeSession.h"
#import "ACCSessionServiceContainer.h"
#import <CreativeKit/ACCServiceLocator.h>

@interface ACCCreativeSession()

@property (nonatomic, strong, readonly) NSHashTable *holdersTable;

@end

@implementation ACCCreativeSession

- (instancetype)initWithCreateId:(NSString *)createId
{
    self = [super init];
    if (self) {
        _createId = createId;
        _holdersTable = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addHolder:(id)holder
{
    [self.holdersTable addObject:holder];
}

- (NSArray *)holders
{
    return self.holdersTable.allObjects;
}

@end
