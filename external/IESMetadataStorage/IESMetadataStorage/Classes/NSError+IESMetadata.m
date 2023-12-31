//
//  NSError+IESMetadata.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/27.
//

#import "NSError+IESMetadata.h"

static NSString * const IESMetadataStorageErrorDomain = @"IESMetadataStorageErrorDomain";

@implementation NSError (IESMetadata)

+ (instancetype)iesmetadata_errorWithCode:(IESMetadataErrorCode)code
                              description:(NSString *)description
{
    return [NSError errorWithDomain:IESMetadataStorageErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : description ? : @"" }];
}

@end

