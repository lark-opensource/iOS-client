//
//  BDWebSecureLinkCustomSetting.h
//  BDWebKit
//
//  Created by bytedance on 2020/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDSecureLinkAreaOptionInline,    //国内
    BDSecureLinkAreaOptionVA,       //美东
    BDSecureLinkAreaOptionSG,       //新加坡
} BDSecureLinkAreaOption;

@protocol BDWebSecureLinkSettingDelegate <NSObject>

@optional
-(BOOL)shouldInterceptFirstJump:(NSURL*)url withResponse:(NSURL*)responseURL;

@end

@interface BDWebSecureLinkCustomSetting : NSObject

/// 安全校验错误个数阈值，【默认为3】
@property (nonatomic, assign) UInt32 errorOverwhelmingCount;

/// 安全校验错误个数阈值的校验区间，即在errorOverwhelmingDuration时间内发生了errorOverwhelmingCount个error则会触发一段时间内不进行，【默认为1800】
@property (nonatomic, assign) NSInteger errorOverwhelmingDuration;

/// 安全校验错误超过阈值后的安全区间，区间时间内不进行安全校验，直接通过，【默认为1800】
@property (nonatomic, assign) NSInteger safeDuraionAfterOverWhelming;

/// 重定向同步安全校验的时候的容忍值，超过这个值就会转成异步调用，【默认为1，配置限制小于等于3】
@property (nonatomic, assign) float syncCheckTimeLimit;

/// 安全服务请求的地点，不同地点请求的安全链接域名因为政策会不一样，默认为国内
@property (nonatomic, assign) BDSecureLinkAreaOption area;


@property (nonatomic, weak) id<BDWebSecureLinkSettingDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
