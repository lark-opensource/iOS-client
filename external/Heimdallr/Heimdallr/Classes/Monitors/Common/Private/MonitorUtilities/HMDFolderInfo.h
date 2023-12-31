//
//  HMDFolderInfo.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/19.
//

#import <Foundation/Foundation.h>
#import "HMDDiskUsage.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDFolderInfo : NSObject<HMDDiskVisitor>

@property (nonatomic, assign) BOOL allowCustomLevel;
@property (nonatomic, assign) NSUInteger fileMaxRecursionDepth;
@property (nonatomic, assign) NSInteger collectMinSize;

#pragma mark --- configuration
/// custom path
/// @param configDict custom path info dictionary (key: cutsom relative path)
- (void)customPathWithConfigDict:(NSDictionary *)configDict;

/// clear current cache data
- (void)clearData;

/// user custom need report directory depth
/// @param depathDict depath info dictionary
- (void)addCustomSearchDepathConfig:(NSDictionary *)depathDict;

#pragma mark --- report
/// the current disk directory info that will be reported
/// @param appFolderSize current home directory size
- (NSArray *)reportDiskFolderInfoWithAppFolderSize:(double)appFolderSize;

- (NSArray *)reportDiskFolderInfoWithAppFolderSize:(double)appFolderSize compliancePaths:(NSArray<NSString*>* _Nullable)compliancePaths;

/// estimate app's documents and data size(Settings->General->iPhone Storage->App->Documents & Data)
- (NSInteger)sizeOfDocumentsAndData;

@end

NS_ASSUME_NONNULL_END
