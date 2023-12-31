//
//  BDPAppPagePrefetchDataModel.h
//  Timor
//
//  Created by 李靖宇 on 2019/11/27.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPNetworkProtocol.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPPrefetchState)
{
    BDPPrefetchStateExceedLimit = -2,// prefetch 请求数量超出限制
    BDPPrefetchStateFail    = -1,    //获取失败
    BDPPrefetchStateUnknown = 0,     //未知状态，未开始(默认)
    BDPPrefetchStateDoing   = 1,     //正在获取状态
    BDPPrefetchStateDown    = 2      //已经取到数据状态
};

typedef void (^PageRequestCompletionBlock)(id _Nullable data, id<BDPNetworkResponseProtocol> _Nullable response, NSInteger prefetchDetail, NSError * _Nullable error);


@interface BDPAppPagePrefetchDataModel : NSObject

@property (nonatomic, assign) BDPPrefetchState state;
@property (nonatomic, assign) NSTimeInterval successTimeStamp;

@property (nonatomic, strong) id data;
@property (nonatomic, strong) id<BDPNetworkResponseProtocol> response;
@property (nonatomic, copy, nullable) PageRequestCompletionBlock completionBlock;

@end

NS_ASSUME_NONNULL_END
