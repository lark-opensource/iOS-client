//
//  ACCBaseApiModel.h
//  ACCme
//
//  Created by HongTao on 2017/2/15.
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <Mantle/Mantle.h>
#import "NSDictionary+ACCAddBaseApiPropertyKey.h"

@interface ACCBaseApiModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *requestID;
@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSNumber *timestamp;
@property (nonatomic, strong) NSString *statusMsg;
@property (nonatomic, strong) NSDictionary *logPassback;


- (void)mergeAllPropertyKeysWithRequestId;
- (void)mergeAllPropertyKeysWithLogPassback;

@end

