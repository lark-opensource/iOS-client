//
//  BDPScopeConfig.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/26.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface BDPScopeConfigEntity : JSONModel

/**
 默认权限弹窗的标题
 */
@property (nonatomic, copy) NSString *scopeName;

@end

@interface BDPScopeConfig : JSONModel

@property (nonatomic, strong) BDPScopeConfigEntity *album;
@property (nonatomic, strong) BDPScopeConfigEntity *camera;
@property (nonatomic, strong) BDPScopeConfigEntity *location;
@property (nonatomic, strong) BDPScopeConfigEntity *address;
@property (nonatomic, strong) BDPScopeConfigEntity *userInfo;
@property (nonatomic, strong) BDPScopeConfigEntity *microphone;
@property (nonatomic, strong) BDPScopeConfigEntity *phoneNumber;
@property (nonatomic, strong) BDPScopeConfigEntity *clipboard;
@property (nonatomic, strong) BDPScopeConfigEntity *appBadge;
@property (nonatomic, strong) BDPScopeConfigEntity *runData;
@end
