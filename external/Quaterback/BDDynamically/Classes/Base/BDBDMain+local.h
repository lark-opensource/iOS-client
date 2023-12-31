//
//  AweQuaterbackSDK+extension.h
//  Quaterback
//
//  Created by hopo on 2021/8/19.
//

#import "BDBDMain.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDBDQuaterbackInfo : NSObject
///解密后包所在文件目录
@property (nonatomic, copy) NSString *path;

///包名
@property (nonatomic, copy) NSString *name;
///版本号
@property (nonatomic, assign) int version;
/// 是否异步加载xx包：默认异步
@property (nonatomic, assign) BOOL async;
/// 补丁id
@property (nonatomic, copy) NSString *moduleId;
/// 跳过补丁文件名检查，默认不跳过
@property (nonatomic, assign) BOOL skipsFileNameValidation;
@end

@interface BDBDMain (local)
/**
 解压ZIP文件至指定的目录

 @param path                ZIP文件路径
 @param destination         解压文件的路径
 @param completionHandler   解压完成回调
 @return 成功返回YES，否则返回NO
 */
+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
             completion:(void (^_Nullable)(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error))completionHandler;


///加载patch包
+ (void)loadQuaterbackWithInfo:(BDBDQuaterbackInfo *)info error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
