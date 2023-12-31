//
//  HMDCDConfig.h
//  Heimdallr
//
//  Created by maniackk on 2020/11/4.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"


extern NSString *const kHMDModuleCoreDump;//线上coredump

@interface HMDCDConfig : HMDModuleConfig

@property (nonatomic, assign) NSUInteger minFreeDiskUsageMB; //当可用磁盘大于minFreeDiskUsageMB，才会生成coredump文件；默认值1000MB
@property (nonatomic, assign) NSUInteger maxCDFileSizeMB;//coredump生成的文件尺寸的最大值，单位MB；默认500MB
@property (nonatomic, assign) NSUInteger maxCDZipFileSizeMB;//coredump原始文件压缩后，如果大于此值，就会删除此压缩文件，不会上传；默认100MB
// 是否捕获NSException类型crash，默认YES
@property (nonatomic, assign) BOOL dumpNSException;
// 是否捕获Cpp类型crash，默认YES
@property (nonatomic, assign) BOOL dumpCPPException;

@end

