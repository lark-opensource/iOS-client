//
//  HMDCloudCommandManager.h
//  
//
//  Created by fengyadong on 2018/8/22.
//

#import <Foundation/Foundation.h>
#import "HeimdallrLocalModule.h"
#import <AWECloudCommand/AWECloudCommandModel.h>

extern NSString * _Nullable const kHMDModuleCloudCommand;

/**
 @typedef CloudCommandAlogUploadBlock
 @fetchStartTime 回捞起始时间
 @fetchEndTime 回捞结束时间
 @count 回捞文件数
 @status 回捞状态，0-未上传；1-上传中；2上传成功；3-上传失败
 @errorMessage 错误信息
 */
typedef void (^CloudCommandAlogUploadBlock)(long long fetchStartTime, long long fetchEndTime, long count, int status, NSString * _Nullable errorMessage);

@interface HMDCloudCommandManager : NSObject<HeimdallrLocalModule>

@property (nonatomic, copy, nullable) CloudCommandAlogUploadBlock alogUploadBlock;

+ (instancetype _Nullable )sharedInstance;

- (void)executeCommandWithData:(NSData * _Nullable)data ran:(NSString * _Nullable)ran;

/**
 是否自动开启云控指令的自动拉取

 @param enabled 是否开启，默认开启，自己实现的话可以手动关闭
 */
- (void)setAutoPullCommandEnable:(BOOL)enabled;

#if !RANGERSAPM
/**
 Config block list for upload

 @param blockList These file paths are not allowed to upload, e.g. @[@"/Library", @"/Library/directory", @"/Library/directory/file.type"]
 */
- (void)setFilePathBlockList:(NSArray<NSString *> * _Nullable)blockList;

/**
 设置回调，业务方可以通过回调控制回捞是否执行
 */

- (void)setIfForbidCloudCommandBlock:(BOOL (^_Nullable)(AWECloudCommandModel * _Nullable model))block;
#endif

@end
