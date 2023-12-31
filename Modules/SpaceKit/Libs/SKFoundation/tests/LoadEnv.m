//
//  LoadEnv.m
//  SKDrive_Tests
//
//  Created by bupozhuang on 2022/3/24.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
@interface FoundationLoadEnv: NSObject

@end

@implementation FoundationLoadEnv

+ (void)load {
    printf("LoadEnv: did set env");
    setenv("IS_TESTING_DOCS_SDK","1",1); // does overwrite
}

@end
