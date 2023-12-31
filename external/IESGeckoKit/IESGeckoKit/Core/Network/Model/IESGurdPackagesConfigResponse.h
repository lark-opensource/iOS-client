//
//  IESGurdPackagesConfigResponse.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/3/1.
//

#import <Foundation/Foundation.h>

#import "IESGeckoResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPackagesConfigResponse : NSObject

@property (nonatomic, strong) id packages;

@property (nonatomic, strong) NSDictionary *local;

@property (nonatomic, copy) NSString *logId;

@property (nonatomic, strong) NSDictionary *appLogParams;

@end

NS_ASSUME_NONNULL_END
