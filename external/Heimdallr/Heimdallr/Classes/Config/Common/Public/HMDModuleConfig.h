//
//  HMDModuleConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import <Foundation/Foundation.h>



@protocol HeimdallrModule;
@protocol HeimdallrLocalModule;
@class HMDGeneralAPISettings;

@interface HMDModuleConfig : NSObject

@property (nonatomic, assign)BOOL enableOpen;   //控制是否开启
@property (nonatomic, assign)BOOL enableUpload; //控制是否上传log

/**
 返回所有远程开关控制的模块的module类

 @return 所有开关控制的模块的module类
 */
+ (nullable NSArray *)allRemoteModuleClasses;

/**
 返回所有本地默认开启的module类

 @return  返回所有本地默认开启的module类
 */
+ (nullable NSArray<HeimdallrLocalModule> *)allLocalModuleClasses;

+ (nullable NSString *)configKey;

- (nonnull instancetype)initWithDictionary:(nullable NSDictionary *)data;

- (nullable id<HeimdallrModule>)getModule;

- (BOOL)isValid;

- (BOOL)canStart;

- (BOOL)canStartTaskIndependentOfStart;

- (void)updateWithAPISettings:(nonnull HMDGeneralAPISettings *)apiSettings;

@end


