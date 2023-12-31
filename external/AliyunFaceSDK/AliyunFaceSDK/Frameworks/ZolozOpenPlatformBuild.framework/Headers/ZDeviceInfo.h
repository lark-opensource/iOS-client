//
//  ZDeviceInfo.h
//  ZolozOpenPlatformBuild
//
//  Created by richard on 26/02/2018.
//  Copyright © 2018 com.alipay.iphoneclient.zoloz. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface ZDeviceInfo : NSObject

@property(nonatomic, strong)NSString * apdidToken;

+(instancetype)getInstance;

-(NSString*) getTokenContent;

-(void)ActivityToken;

-(void)ActivityTokenWithParam:(NSDictionary*)param;

@end
