//
//  ACCUserModelProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/6/17.
//

#ifndef ACCUserModelProtocolD_h
#define ACCUserModelProtocolD_h

#import <CreationKitArch/ACCUserModelProtocol.h>

@protocol ACCUserModelProtocolD <ACCUserModelProtocol>

@property (nonatomic, assign) BOOL isGovMediaVip;// State Administration number
@property (nonatomic, assign) BOOL allowShare;
@property (nonatomic, strong, nullable) NSString *enterpriseVerifyInfo; // 企业认证简介

@end

#endif /* ACCUserModelProtocolD_h */
