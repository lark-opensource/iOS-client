//
//  Converter.h
//  GenModel
//
//  Created by lxp on 2020/2/11.
//  Copyright © 2020 lxp. All rights reserved.
//
#import <Foundation/Foundation.h>
#include <string>
@interface LVDataConverter : NSObject

+ (NSString *)covertCPPString:(const std::string)string;

+ (std::string)covertObjCString:(NSString *)string;

@end

