//
//  IESGurdFetchResourcesResult.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdFetchResourcesResult : NSObject

@property (nonatomic, assign) BOOL succeed;

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) IESGurdSyncStatusDict statusDictionary;

@end

NS_ASSUME_NONNULL_END
