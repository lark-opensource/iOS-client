//
//  DemoEnv.h
//  KADemoAssemble
//
//  Created by Supeng on 2021/12/15.
//

#import <Foundation/Foundation.h>
@class KATabConfig;
@protocol FilePreviewer;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface DemoEnv : NSObject
/// App 根VC
+(UIViewController*)rootViewController;
/// 返回所有注册的Tab
+(NSArray<KATabConfig*>*)allTabConfigs;
/// 返回所有注册的filePreviewer
+(NSArray<id<FilePreviewer>>*)allFilePreviewers;
@end

NS_ASSUME_NONNULL_END
