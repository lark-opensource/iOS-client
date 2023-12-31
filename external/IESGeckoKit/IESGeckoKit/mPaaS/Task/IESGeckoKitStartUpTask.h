//
//  IESGeckoKitStartUpTask.h
//  IESGeckoKit
//
//  Created on 2020/4/10.
//

#import <BDStartUp/BDStartUpTask.h>

NS_ASSUME_NONNULL_BEGIN

/// Config自定义配置参考如下，需要在BDAppCustomConfigFunction中
/// 仅做简单配置，请勿进行耗时操作
///
/**
#import <BDStartUp/BDStartUpGaia.h>
#import <IESGeckoKit/IESGeckoKitStartUpTask.h>
 
BDAppCustomConfigFunction() {
    [IESGeckoKitStartUpTask sharedInstance].xx = xxx;
 }
 */


@interface IESGeckoKitStartUpTask : BDStartUpTask

@property (nonatomic, copy) NSString *rootDirectoryPath;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END

