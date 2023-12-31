//
//  ACCFlowerAuditDataService.h
//  Indexer
//
//  Created by wanghongyu on 2021/11/30.
//

#import <Foundation/Foundation.h>

@protocol ACCFlowerAuditDataService <NSObject>

- (void)unzipAuditPackageIfNeeded;
- (nullable NSString *)auditPackagePath;
- (void)clearAuditPackage;

@end

