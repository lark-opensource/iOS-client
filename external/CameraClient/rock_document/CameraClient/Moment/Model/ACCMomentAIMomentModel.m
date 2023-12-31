//
//  ACCMomentAIMomentModel.m
//  Pods
//
//  Created by Pinka on 2020/5/25.
//

#import "ACCMomentAIMomentModel.h"

@implementation ACCMomentAIMomentModel

- (NSString *)description
{
    return [NSString stringWithFormat:@"momentId=%@,type=%@", self.identity, self.type];
}

@end
