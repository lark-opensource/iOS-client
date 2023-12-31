//
//  NSError+IESGurdKit.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kIESGurdKitErrorDomain;

@interface NSError (IESGurdKit)

+ (instancetype)ies_errorWithCode:(IESGurdSyncStatus)status description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
