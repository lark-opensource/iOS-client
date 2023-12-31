//
//  BDXBridgeGetUserInfoMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/29.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeGetUserInfoMethod : BDXBridgeMethod

@end

@interface BDXBridgeGetUserInfoMethodResultUserInfoModel : BDXBridgeModel

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *secUserID;
@property (nonatomic, copy) NSString *uniqueID;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, assign) BOOL hasBoundPhone;

@end

@interface BDXBridgeGetUserInfoMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BOOL hasLoggedIn;
@property (nonatomic, strong) BDXBridgeGetUserInfoMethodResultUserInfoModel *userInfo;

@end

NS_ASSUME_NONNULL_END
