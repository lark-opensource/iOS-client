//
//  IESGurdDownloadPackageInfo.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDownloadPackageInfo : NSObject

@property (nonatomic, assign, getter=isSuccessful) BOOL successful;

@property (nonatomic, assign) uint64_t downloadSize; //单位：bytes

@property (nonatomic, assign, getter=isPatch) BOOL patch; //是否增量包

@property (nonatomic, assign) uint64_t packageId;

@property (nonatomic, assign) NSInteger downloadDuration;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;

@property (nonatomic, assign) IESGurdDownloadPriority downloadPriority;

@end

NS_ASSUME_NONNULL_END
