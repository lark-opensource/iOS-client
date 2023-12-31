//
//  NSError+IESMetadata.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESMetadataErrorCode) {
    IESMetadataErrorCodeWrite
};

@interface NSError (IESMetadata)

+ (instancetype)iesmetadata_errorWithCode:(IESMetadataErrorCode)code
                              description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
