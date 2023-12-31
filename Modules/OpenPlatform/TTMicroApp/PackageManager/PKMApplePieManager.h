//
//  PKMApplePieManager.h
//  TTMicroApp
//
//  Created by Nicholas Tau on 2023/3/20.
//

#import <Foundation/Foundation.h>
@class BDPUniqueID;
NS_ASSUME_NONNULL_BEGIN

@interface PKMApplePieManager : NSObject
+ (instancetype)sharedManager;

/// 预热资源，飞书启动时准备提前加载各种 ODR 的资源
/// - Parameter pies:需要预热的 ODR 资源
/// ///   - completionBlock: 异步callback，每完成一个 ODR 预热都会执行
-(void)warmPies:(NSArray<BDPUniqueID *> *) pies
withCompletion:(void (^)(NSError * _Nullable error, BDPUniqueID *pie))completionBlock;

///  启动应用时异步获取需要的资源，需要马上请求
/// - Parameters:
///   - pie: 资源描述
///   - completionBlock: 异步callback
-(void)makePieImmediately:(BDPUniqueID *) pie
           withCompletion:(void (^)(NSError * _Nullable error, BDPUniqueID *pie))completionBlock;

//给ODR资源的bundle目录，默认是和json文件路径一样（非ODR，走内置）
//开关开启的情况下在 mainBundle 内
//如果是JSON文件，只返回相对bundle，只有包文件才返回mainBundle路径
-(NSString * _Nullable)bundlePathForBuildin:(BOOL)isPie;

//给ODR资源的bundle目录，默认是和json文件路径一样（非ODR，走内置）
//开关开启的情况下在 mainBundle 内
-(NSString * _Nullable)specificPathForPie:(BDPUniqueID *)pie;
@end

NS_ASSUME_NONNULL_END
