//
//  BDPModel+Private.h
//  Timor
//
//  Created by houjihu on 2020/7/27.
//

#import "BDPModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AppMetaPackageProtocol;
@interface BDPModel ()

@property (nonatomic, copy, readwrite) NSString *pkgName;
@property (nonatomic, copy, readwrite) NSArray<NSURL *> *urls;

@property (nonatomic, strong, readwrite) id<AppMetaPackageProtocol> package;
@property (nonatomic, copy, readwrite, nullable) NSString *appVersion;

@end

NS_ASSUME_NONNULL_END
