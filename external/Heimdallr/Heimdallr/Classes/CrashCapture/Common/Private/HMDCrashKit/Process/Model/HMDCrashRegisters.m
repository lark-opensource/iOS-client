//
//  HMDCrashRegisters.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashRegisters.h"

@implementation HMDCrashRegisters

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    
    self.registers = dict;
}

@end
