//
//  HMDAddressUnit.m
//  Heimdallr
//
//  Created by fengyadong on 2020/11/18.
//

#import "HMDAddressUnit.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDAddressUnit

- (NSDictionary *)unitToDict {
    NSString *name = self.name ?: @"--";
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:@[name, @(self.address)] forKeys:@[@"name", @"value"]];
    
    return dict;
}

@end
