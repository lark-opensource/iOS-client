//
//  ACCMeasureOnceItem.m
//  Pods
//
//  Created by 郝一鹏 on 2019/8/12.
//

#import "ACCMeasureOnceItem.h"

@interface ACCMeasureOnceItem ()

@property (nonatomic, assign) BOOL didSet;

@end

@implementation ACCMeasureOnceItem

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = [[name mutableCopy] copy];
    }
    return self;
}

- (void)setTimestamp:(NSTimeInterval)timestamp
{
    if (self.didSet) {
        return;
    }
    _timestamp = timestamp;
    self.didSet = YES;
}

@synthesize name = _name;

@end
