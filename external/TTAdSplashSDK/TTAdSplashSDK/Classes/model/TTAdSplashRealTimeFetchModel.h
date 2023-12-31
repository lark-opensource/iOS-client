//
//  TTAdSplashRealTimeFetchModel.h
//  TTAdSplashSDK
//
//  Created by bytedance on 2018/7/9.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface TTAdSplashRealTimeFetchModelItem : JSONModel
@property (nonatomic, strong) NSString *item_key;
@property (nonatomic, copy) NSString *splash_id;
@property (nonatomic, copy) NSString *log_extra;
@property (nonatomic, copy) NSString *splash_ad_id;
@end

@protocol TTAdSplashRealTimeFetchModelItem;

@interface TTAdSplashRealTimeFetchModel : JSONModel

@property (nonatomic, strong) NSArray<TTAdSplashRealTimeFetchModelItem> *splash;
@property (nonatomic, strong) NSArray<NSString *> *withdraw;
@property (nonatomic, assign) NSInteger command;
/// 服务端下发的实时通用log_extra兜底
@property (nonatomic, strong) NSString *log_extra;

/// 开屏实时控制序列 为空
@property (nonatomic, assign) BOOL isEmptyModel;
@property (nonatomic, assign) BOOL realFecthSucceed;

@end
