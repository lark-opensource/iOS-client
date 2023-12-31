//
//  BDWebResourceLoaderURLProtocol.h
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const BDWebRLUrlProtocolErrorDomain;

typedef NS_ERROR_ENUM(BDWebRLUrlProtocolErrorDomain, BDWebRLUrlProtocolCode) {
    BDWebRLUrlProtocolUnknow = 0,
    BDWebRLUrlProtocolLResourceMissingAfterCanInit = -1,
};

@protocol BDWebURLSchemeProtocolClass;

@interface BDWebResourceLoaderURLProtocol : NSURLProtocol<BDWebURLSchemeProtocolClass>


@end

NS_ASSUME_NONNULL_END
