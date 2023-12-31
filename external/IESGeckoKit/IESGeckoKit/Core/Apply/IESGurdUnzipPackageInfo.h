//
//  IESGurdUnzipPackageInfo.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdUnzipPackageInfo : NSObject

@property (nonatomic, assign, getter=isSuccessful) BOOL successful;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, assign) NSInteger unzipDuration;

@end

NS_ASSUME_NONNULL_END
