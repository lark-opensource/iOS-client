//
//  BDASplashControlModel.h
//  TTAdSplashSDK
//
//  Created by YangFani on 2020/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,BDASplashControlActionType){
    BDASplashControlActionTypeTest = 1,
    BDASplashControlActionTypeClearCids = 1 << 1,   ///< =2  清除 cids 中所对应的缓存
    BDASplashControlActionTypeClearCache = 1 << 2,  ///< =4  清除某段时间端缓存
    BDASplashControlActionTypeCallBack   = 1 << 3,  ///< =8  回调打包的接口
};

typedef NS_ENUM(NSInteger,BDASplashControlPlatform){
    BDASplashControlPlatformAndroid = 1,
    BDASplashControlPlatformIOS = 1 << 1,   ///< =2 指定ios执行
};

@interface BDASplashControlModel : NSObject

@property (nonatomic, assign) BDASplashControlPlatform platform;         ///<需要执行的平台
@property (nonatomic, assign) BDASplashControlActionType action;         ///<下发操作类型
@property (nonatomic, copy) NSArray<NSNumber *> *cids;                   ///<需要清除的广告id
@property (nonatomic, copy) NSArray<NSString *> *clearCaches;            ///<需要清除的广告时间段
@property (nonatomic, copy) NSString *logExtra;                          ///<打点字段

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
