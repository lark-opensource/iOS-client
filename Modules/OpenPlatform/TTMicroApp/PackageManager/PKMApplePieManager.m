//
//  PKMApplePieManager.m
//  TTMicroApp
//
//  Created by Nicholas Tau on 2023/3/20.
//

#import "PKMApplePieManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPSDK/OPSDK-Swift.h>

@interface PKMApplePieManager()
@end

@interface OPAppUniqueID (PieTag)
-(NSString *)resourceTag;
@end

@implementation OPAppUniqueID (PieTag)
-(NSString *)resourceTag
{
    //直接用AppID的identifier，作为resourceTag
    return self.identifier;
}
@end

@implementation PKMApplePieManager
+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static PKMApplePieManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[PKMApplePieManager alloc] init];
    });
    
    return manager;
}

/// 预热资源，飞书启动时准备提前加载各种 ODR 的资源
/// - Parameter pies:需要预热的 ODR 资源
/// ///   - completionBlock: 异步callback，每完成一个 ODR 预热都会执行
-(void)warmPies:(NSArray<BDPUniqueID *> *) pies
 withCompletion:(void (^)(NSError * error, BDPUniqueID *pie))completionBlock
{
    BDPLogInfo(@"PKMApplePieManager: warmPies with count:%@", @(pies.count));
    if(!BDPIsEmptyArray(pies)) {
        //挨个请求 pie
        for (BDPUniqueID *pie in pies) {
            //默认优先级 0.5
            [self makePieImmediately:pie
                            priority:.5
                      withCompletion:completionBlock];
        }
    }
}

///  启动应用时异步获取需要的资源，需要马上请求
/// - Parameters:
///   - pie: 资源描述
///   - completionBlock: 异步callback
-(void)makePieImmediately:(BDPUniqueID *) pie
           withCompletion:(void (^)(NSError * _Nullable error, BDPUniqueID *pie))completionBlock
{
    //请求之前先判断一下资源在bunle里是否已存在，如果存在就不需要额外请求
    [self makePieImmediately:pie
                    priority:.0
              withCompletion:completionBlock];
}

// priority 优先级
// 直接作用于 NSBundleResourceRequest
-(void)makePieImmediately:(BDPUniqueID *) pie
                 priority:(float) priority
           withCompletion:(void (^)(NSError * error, BDPUniqueID *pie))completionBlock
{
    BDPLogInfo(@"PKMApplePieManager: begin to access resource with uniqueID:%@ and priority:%@", pie, @(priority));
    int retryCount = 0;
    [self beginAccessingResourcesWith:pie
                           retryCount:retryCount
                           completion:completionBlock];
}

-(void)beginAccessingResourcesWith:(BDPUniqueID *)pie retryCount:(int) count completion:(void (^)(NSError * _Nullable error, BDPUniqueID *pie))completionBlock
{
    //可以重试三次
    //请求之前先判断一下资源在bunle里是否已存在，如果存在就不需要额外请求
    NSString * resourceTag = pie.resourceTag;
    NSBundleResourceRequest * bundleRequest = [[NSBundleResourceRequest alloc] initWithTags:[NSSet setWithObject:resourceTag]];
    bundleRequest.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent;
    //开始请求 ODR 资源
    CommonMonitorWithNameIdentifierType(kEventName_op_odr_download_start, pie)
    .flush();
    OPMonitorEvent *monitorResult =
    CommonMonitorWithNameIdentifierType(kEventName_op_odr_download_result, pie)
        .addCategoryValue(@"retryCount",@(count))
        .timing();
    //0、1、2，尝试三次
    if(count<3){
        [bundleRequest beginAccessingResourcesWithCompletionHandler:^(NSError * _Nullable error) {
            //发生了错误，需要记录一下。
            if(error){
                NSString * errorMsg = error ? error.localizedDescription : @"null error info";
                BDPLogError(@"PKMApplePieManager: beginAccessingResourcesWithCompletionHandler with error:%@ and uniqueID:%@", errorMsg, pie);
                monitorResult
                    .setResultTypeFail()
                    .setError(error)
                    .flush();
                //进行重试
                [self beginAccessingResourcesWith:pie
                                       retryCount:count+1
                                       completion:completionBlock];
            }else{
                monitorResult
                    .setResultTypeSuccess()
                    .timing()
                    .flush();
                //资源请求成功，可以进行一些安装的操作
                completionBlock(error, pie);
                BDPLogInfo(@"PKMApplePieManager: accessingResource finished");
            }
        }];
    }else{
        BDPLogInfo(@"PKMApplePieManager out of times");
        monitorResult.setError([NSError errorWithDomain:@"com.lark.openplatform.pkm"
                                                   code:-1
                                               userInfo:@{NSLocalizedDescriptionKey:@"retry count up to count"}])
        .setResultTypeFail()
        .flush();
    }
}

//给ODR资源的bundle目录，默认是和json文件路径一样（非ODR，走内置）。开关开启的情况下在 mainBundle 内
-(NSString * _Nullable)bundlePathForBuildin:(BOOL)isPie
{
    if(isPie && [OPSDKFeatureGating isEnableApplePie]) {
        return NSBundle.mainBundle.bundlePath;
    }
    NSURL * timorBundleUrl = [NSBundle.mainBundle URLForResource:@"TimorAssetBundle" withExtension:@"bundle"];
    NSBundle * mainBundle = [NSBundle bundleWithURL:timorBundleUrl];
    return [mainBundle pathForResource:@"BuildinResources.bundle" ofType:@""];
}

-(NSString * _Nullable)specificPathForPie:(BDPUniqueID *)pie
{
    //判断文件类型
    BDPPackageType pkgType = (pie.appType == OPAppTypeGadget && ![OPSDKFeatureGating isEnableApplePie]) ? BDPPackageTypePkg : BDPPackageTypeZip;
    //根据文件类型得到扩展名
    NSString * extensionName = (pkgType == BDPPackageTypePkg) ? @"pkg" : @"zip";
    //返回具体的资源目录
    return [NSBundle.mainBundle pathForResource:pie.identifier ofType:extensionName];
}

@end
