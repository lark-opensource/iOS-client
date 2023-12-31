//
//  BDPNetworkAPIVersionConfig.h
//  TTMicroApp
//
//  Created by MJXin on 2022/1/26.
//

#import <OPFoundation/BDPBaseJSONModel.h>

typedef NS_ENUM(NSUInteger, BDPNetworkAPIVersionType) {
    BDPNetworkAPIVersionTypeUnknown,
    BDPNetworkAPIVersionTypeV1,
    BDPNetworkAPIVersionTypeV2,
};

@interface BDPNetworkAPIVersionConfig : BDPBaseJSONModel
@property (nonatomic, strong) NSString *requestVersion;
@property (nonatomic, strong) NSString *uploadFileVersion;
@property (nonatomic, strong) NSString *downloadFileVersion;
@end

@interface NSString(BDPNetworkAPIVersionConfig)
- (BDPNetworkAPIVersionType)networkAPIVersionType;
@end

