//
//  BDDYCZipArchive.h
//  BDDynamically
//
//  Created by zuopengliu on 15/3/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

#if BDAweme
__attribute__((objc_runtime_name("AWECFDahlia")))
#elif BDNews
__attribute__((objc_runtime_name("TTDNettle")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDAlligator ")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDCauliflower")))
#endif
@interface BDDYCZipArchive : NSObject

/**
 解压ZIP文件至指定的目录
 
 @param path                ZIP文件路径
 @param destination         解压文件的路径
 @param completionHandler   解压完成回调
 @return 成功返回YES，否则返回NO
 */
+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
             privateKey:(NSString * _Nullable)privateKey // 对称加密私钥(AES)
             completion:(void (^_Nullable)(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error))completionHandler;

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

@end


NS_ASSUME_NONNULL_END
