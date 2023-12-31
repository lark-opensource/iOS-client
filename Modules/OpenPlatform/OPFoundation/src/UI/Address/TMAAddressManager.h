//
//  TMAAddressManager.h
//  TTMicroApp-Example
//
//  Created by linxiaoyuan on 2018/6/25.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMAAddressManager : NSObject

+ (instancetype)shareInstance;
- (NSArray *)getAreaArray;

@end
