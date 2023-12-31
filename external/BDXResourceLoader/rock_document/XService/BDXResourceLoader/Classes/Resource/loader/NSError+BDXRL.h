//
//  NSError+BDXResourceLoader.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXRLErrorCode) {
    BDXRLErrorCodeCancel = 1000,
    BDXRLErrorCodeNoProcessor,
    BDXRLErrorCodeEmptyParam,
    BDXRLErrorCodeURLInvalid,
    BDXRLErrorCodeNoData,
    BDXRLErrorCodeGurdNoParams,
    BDXRLErrorCodeGurdFaile,
};

@interface NSError (BDXRL)

+ (NSError *)errorWithCode:(BDXRLErrorCode)errorcode message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
