//
//  AweQuaterbackSDK+extension.h
//  Quaterback
//
//  Created by hopo on 2021/8/19.
//

#import "AweQuaterbackSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface AweQuaterbackInfo : NSObject
///解密后包所在文件目录
@property (nonatomic, copy) NSString *path;

///包名
@property (nonatomic, copy) NSString *name;
///版本号
@property (nonatomic, copy) NSString *version;
/// 是否异步加载xx包：默认异步
@property (nonatomic, assign) BOOL async;
/// 补丁id
@property (nonatomic, copy) NSString *moduleId;
@end

@interface AweQuaterbackSDK (local)
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
+ (void)loadQuaterbackWithInfo:(AweQuaterbackInfo *)info error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
