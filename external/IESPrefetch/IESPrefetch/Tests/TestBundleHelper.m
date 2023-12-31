//
//  TestBundleHelper.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>

@interface TestBundleHelper : NSObject

@end

@implementation TestBundleHelper

@end

NSString *pathForResource(NSString *resourceName, NSString *resourceType)
{
    NSString *path = [[NSBundle bundleForClass:[TestBundleHelper class]] pathForResource:resourceName ofType:resourceType];
    return path;
}

NSDictionary *jsonDictFromResource(NSString *resourceName, NSString *resourceType)
{
    NSString *path = [[NSBundle bundleForClass:[TestBundleHelper class]] pathForResource:resourceName ofType:resourceType];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return dict;
}
