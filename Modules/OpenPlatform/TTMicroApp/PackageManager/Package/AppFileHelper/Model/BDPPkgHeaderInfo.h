//
//  BDPPkgHeaderInfo.h
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import <Foundation/Foundation.h>
@class BDPPkgFileIndexInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 流式包文件描述信息(基础信息+各文件索引)
 
 下载器与加载器皆使用实例
 */
@interface BDPPkgHeaderInfo : NSObject <NSCoding>

/** 自定义缓存结构版本 */
@property (nonatomic, assign) uint32_t customVersion;

/** 文件版本号, 非应用版本号 */
@property (nonatomic, assign) uint32_t version;
/** 拓展数据 */
@property (nonatomic, nullable, copy) NSData *extInfo;

/** 各文件索引 */
@property (nonatomic, copy) NSArray<BDPPkgFileIndexInfo *> *fileIndexes;
/** 字典索引 */
@property (nonatomic, copy) NSDictionary<NSString *, BDPPkgFileIndexInfo *> *fileIndexesDic;

/** 文件总大小 */
@property (nonatomic, assign) int64_t totalSize;

@end


/** 流式包文件索引信息 */
@interface BDPPkgFileIndexInfo : NSObject <NSCoding>

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) uint32_t offset;
@property (nonatomic, assign) uint32_t size;

@property (nonatomic, readonly) uint32_t endOffset;

@end

NS_ASSUME_NONNULL_END
