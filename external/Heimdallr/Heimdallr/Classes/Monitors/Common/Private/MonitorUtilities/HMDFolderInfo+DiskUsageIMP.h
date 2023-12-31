//
//  HMDFolderInfo+DiskUsageIMP.h
//  Heimdallr-85f794d0
//
//  Created by zhangxiao on 2020/7/9.
//

#import "HMDFolderInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDFolderInfo (DiskUsageIMP)

// the IMP of HMDDiskVisitor delegate
- (void)visitDirectory:(NSString *)path size:(NSUInteger)size deepLevel:(NSUInteger)deepLevel;
- (void)visitFile:(NSString *)path size:(NSUInteger)size lastAccessDate:(NSDate *)date deepLevel:(NSInteger)deepLevel;

@end

NS_ASSUME_NONNULL_END
