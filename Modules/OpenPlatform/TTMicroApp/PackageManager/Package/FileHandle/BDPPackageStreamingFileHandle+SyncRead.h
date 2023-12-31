//
//  BDPPackageStreamingFileHandle+SyncRead.h
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileHandle.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle (SyncRead) <BDPPkgFileSyncReadHandleProtocol>

/// 检查文件是否在包内
- (BOOL)__fileExistsInPkgAtPath:(NSString *)filePath withFileInfo:(BDPPkgHeaderInfo *)fileInfo;
/// 同步检查文件是否存在
- (BOOL)syncCheckFileExists:(NSString *)filePath;
/// 查询指定流式包文件的索引信息
- (BDPPkgFileIndexInfo *)indexInfoForFilePath:(NSString *)filePath;
/// 记录文件请求
- (void)recordRequestOfFile:(NSString *)filePath;
/// 获取辅助文件路径
- (NSString *)auxiliaryPathFrom:(NSString *)path appType:(BDPType)appType;
/// 获取指定文件数据
- (NSData *)getDataOfIndexModel:(BDPPkgFileIndexInfo *)model error:(NSError **)error;

/// 将辅助数据（mp3音频等数据）保存到存放pkg包的目录。
/// app包辅助文件目录路径: xxx/tma/app/tt00a0000bc0000def/name/__auxiliary__
- (NSURL *)writeAuxiliaryFileWithData:(NSData *)data
                 uniqueID:(BDPUniqueID *)uniqueID
                              pkgName:(NSString *)pkgName
                              appType:(BDPType)appType
                             filePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
