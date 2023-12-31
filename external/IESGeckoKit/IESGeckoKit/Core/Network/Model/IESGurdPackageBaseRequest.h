//
//  IESGurdPackageBaseRequest.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/11/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESGurdPackageBaseRequestSubclass <NSObject>

- (NSDictionary *)requestMetaDictionary;

- (NSDictionary *)logInfo;

@end

@interface IESGurdPackageBaseRequest : NSObject <IESGurdPackageBaseRequestSubclass>

@property (nonatomic, assign) IESGurdDownloadPriority downloadPriority;

@property (nonatomic, assign) IESGurdPackageModelActivePolicy modelActivePolicy;

@property (nonatomic, assign) BOOL retryDownload;

@property (nonatomic, assign) BOOL forceDownload;

@end

NS_ASSUME_NONNULL_END
