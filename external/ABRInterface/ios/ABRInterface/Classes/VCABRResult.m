//
//  ABRResult.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCABRResult.h"

@interface VCABRResult()

@property (nonatomic, strong) NSMutableArray *elements;

@end

@implementation VCABRResult

- (instancetype)init {
    if (self = [super init]) {
        _elements = [NSMutableArray array];
    }
    return self;
}

- (void)addElement:(VCABRResultElement *)element {
    [self.elements addObject:element];
}

- (int)getSize {
    return (int)self.elements.count;
}

- (VCABRResultElement *)elementAtIndex:(int)index {
    if (index < 0 || index >= self.elements.count) {
        return nil;
    }
    return [self.elements objectAtIndex:index];
}

@end
