//
//  NSMapTable+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSMapTable+OK.h"
#import "NSObject+OK.h"


@implementation NSMapTable (OK)

- (id)ok_safeJsonObject {
    
    return [self.dictionaryRepresentation ok_safeJsonObject];
}

@end
