//
//  BDXResourceLoaderProcessor.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import "BDXRLOperator.h"
#import "BDXRLUrlParamConfig.h"

#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>
#import <BDXServiceCenter/BDXService.h>
#import <BDXServiceCenter/BDXServiceRegister.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark-- ENUM

typedef NS_ENUM(NSInteger, BDXRLGeckoStatus) {
    BDXRLGeckoStatusUnknown = 0,
    BDXRLGeckoStatusUpdateFail,         // 更新失败
    BDXRLGeckoStatusActivateFail,       // 激活失败
    BDXRLGeckoStatusDownloadFail,       // 下载失败
    BDXRLGeckoStatusCheckFail,          // 获取服务器版本失败
    BDXRLGeckoStatusCheckResponseEmpty, // 获取服务器版本的 response 为空
    BDXRLGeckoStatusClientCreationFail, // Gecko client 创建失败
    BDXRLGeckoStatusReadLocalFail,      // 读取本地文件失败
};

typedef NS_ENUM(NSInteger, BDXRLFailedType) { BDXRLFailedTypeGecko = 1, BDXRLFailedTypeCDN, BDXRLFailedTypeBuiltin, BDXRLFailedTypeOther };

#pragma mark-- BDXResourceLoaderBaseProcessor

@interface BDXRLBaseProcessor : NSObject <BDXResourceLoaderProcessorProtocol>

@property(nonatomic, assign) BOOL isCanceled;
@property(nonatomic, strong) BDXRLUrlParamConfig *paramConfig;
@property(nonatomic, strong) BDXRLOperator *advancedOperator;

@end

NS_ASSUME_NONNULL_END
