//
//  BDLynxBundle.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import <Foundation/Foundation.h>
#import "BDLyxnChannelConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBundle : NSObject

@property(nonatomic, copy, readonly) NSString *version;
@property(nonatomic, copy, readonly) NSString *groupID;

@property(nonatomic, assign, readonly) BOOL isSingleFile;
@property(nonatomic, strong, readonly) NSURL *rootDirURL;

@property(nonatomic, readonly) BDLyxnChannelConfig *channelConfig;

@property(copy) NSString *storagePath;  /// 卡片存储目录，用于存放卡片相关数据库、临时文件等资源

/// group 所在目录
/// @param rootDirURL group 所在目录
/// @param groupID groupID
- (instancetype)initWithRootDir:(NSURL *)rootDirURL groupID:(NSString *)groupID;

/// 单文件查找
/// @param fileURL file地址
/// @param groupID groupID
- (instancetype)initWithSingleBundleFileURL:(NSURL *)fileURL groupID:(NSString *)groupID;

/// 使用路径初始化Bundle对象
/// @param path 包含config.jsond的路径
/// @param groupID 对应的groupid
/// @param reason 失败原因
- (instancetype)initWithBundlePath:(NSString *)path
                             group:(NSString *_Nullable)groupID
                             error:(NSString *_Nullable __autoreleasing *_Nullable)reason;

- (NSData *)lynxDataWithCardID:(NSString *)cardID;

/// 获取cardID对应的templateConfig
/// @param cardID  nil时默认返回第一个
- (BDLynxTemplateConfig *)lynxCardDataWithCardID:(nullable NSString *)cardID;

- (NSDictionary *)lynxExtraDataWithCardID:(NSString *)cardID;

- (BOOL)updateDataWithRootDir:(NSURL *)fileUrl;
- (BOOL)updateDataWithSingleBundleFile:(NSURL *)fileUrl;

@end

NS_ASSUME_NONNULL_END
