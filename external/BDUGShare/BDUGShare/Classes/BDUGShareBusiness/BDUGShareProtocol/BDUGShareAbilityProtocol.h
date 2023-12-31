//
//  Header.h
//  Pods
//
//  Created by 杨阳 on 2019/6/6.
//

#import <Foundation/Foundation.h>

@protocol BDUGShareAbilityProtocol <NSObject>

+ (instancetype)sharedInstance;

- (void)shareAbilityShowLoading;

- (void)shareAbilityHideLoading;

@end
