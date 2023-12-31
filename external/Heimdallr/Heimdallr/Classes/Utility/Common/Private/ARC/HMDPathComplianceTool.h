//
//  HMDPathComplianceTool.h
//  Heimdallr
//
//  Created by zhouyang11 on 2022/11/7.
//

#import <Foundation/Foundation.h>

@interface HMDPathComplianceTool : NSObject

/// compliance path depend on the compliancePaths
///   - originalPath: "/tmp/GWPAsanTmp/123/4567.txt"
///   - compliancePaths: ["/tmp/GWPASanTmp","/tmp/test"]
///   - return "tmp/GWPAsanTmp/***/****.txt"
+ (NSString* _Nullable)complianceReleativePath:(NSString* _Nullable)originalPath compliancePaths:(NSArray<NSString*>* _Nullable)compliancePaths;

+ (NSString* _Nullable)compareReleativePath:(NSString* _Nullable)originalPath compliancePaths:(NSArray<NSString *> * _Nullable)compliancePaths isMatch:(BOOL* _Nullable)isCompleteMatch;
+ (NSString* _Nullable)compareAbsolutePath:(NSString* _Nullable)originalPath compliancePaths:(NSArray<NSString *> * _Nullable)compliancePaths isMatch:(BOOL* _Nullable)isCompleteMatch;

///   - originalPath: "tmp/GWPAsanTmp"
///   - compliancePaths: "tmp"
///   - return "tmp/**********"
+ (NSString* _Nullable)complianceReleativePath:(NSString * _Nullable)originalPath prefixPath:(NSString * _Nullable)prefixPath;

@end
