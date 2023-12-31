//
//  IESGurdAutoRequestManager.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/23.
//

#import <Foundation/Foundation.h>

#import "IESGurdSettingsRequestMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdAutoRequestManager : NSObject

+ (instancetype)sharedManager;

- (void)handleRequestMeta:(IESGurdSettingsRequestMeta *)requestMeta;

@end

NS_ASSUME_NONNULL_END
