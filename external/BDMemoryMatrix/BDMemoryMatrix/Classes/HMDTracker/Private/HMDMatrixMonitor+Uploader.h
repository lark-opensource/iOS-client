//
//  HMDMatrixMonitor+Uploader.h
//  BDMemoryMatrix
//
//  Created by YSurfer on 2023/9/12.
//

#import "HMDMatrixMonitor.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *KHMDMatrixZipFileExtension;
extern NSString *KHMDMatrixEnvFileExtension;
extern const char *KALOGMemoryInstance;

@interface HMDMatrixMonitor (Uploader)

+ (NSString *)matrixUploadRootPath;///matrix待上报文件的根路径，存储不同时机的zip+env文件
+ (NSString *)matrixOfExceptionUploadPath;
+ (NSString *)matrixOfMemoryGraphUploadPath;
+ (NSString *)matrixOfCustomUploadPath;
+ (void)removeAllFiles;///移除所有待上报文件

- (void)matrixOfMemoryGraphUpload;
- (void)matrixOfCustomUpload;
- (void)matrixOfExceptionUpload;
- (void)uploadMatrixAlog;

@end

NS_ASSUME_NONNULL_END
