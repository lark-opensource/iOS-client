//
//  AWEBaseApiModel.h
//  Aweme
//
//  Created by HongTao on 2017/2/15.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <IESFoundation/NSDictionary+AWEAdditions.h>
#import "NSDictionary+AWEAddBaseApiPropertyKey.h"

@interface AWEBaseApiModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString * _Nullable requestID;
@property (nonatomic, strong) NSNumber * _Nullable statusCode;
@property (nonatomic, strong) NSNumber * _Nullable timestamp;
@property (nonatomic, strong) NSString * _Nullable statusMsg;
@property (nonatomic, strong) NSDictionary * _Nullable logPassback;

- (void)mergeAllPropertyKeysWithRequestId;
- (void)mergeAllPropertyKeysWithLogPassback;
- (void)mergeAllPropertyKeysWithRequestIdAndLogPassback;

@end

@interface AWEBaseTTApiModel : AWEBaseApiModel

@end

@protocol AWEProcessRequestInfoProtocol <NSObject>

- (void)processRequestID:(NSString * _Nullable)requestID;

@end
