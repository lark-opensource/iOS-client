//
//  HMDNetworkReqModel.h
//  Heimdallr
//
//  Created by fengyadong on 2021/5/12.
//

#import <Foundation/Foundation.h>
#import "HMDJSONObjectProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetworkReqModel : NSObject

@property (nonatomic, copy) NSString *requestURL;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *headerField;
@property (nonatomic, copy, nullable) id<HMDJSONObjectProtocol> params;
@property (nonatomic, assign) BOOL needEcrypt;
@property (nonatomic, assign) BOOL isManualTriggered;

@property (nonatomic, strong, nullable) NSData *postData; // 不需要额外处理，直接发送的数据

@property (nonatomic, assign) BOOL isFromHermas; // 网络请求是否来自Hermas

@end

NS_ASSUME_NONNULL_END
