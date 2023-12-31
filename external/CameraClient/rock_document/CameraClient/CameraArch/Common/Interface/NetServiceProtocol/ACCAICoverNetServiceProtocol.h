//
//  ACCAICoverNetServiceProtocol.h
//  CameraClient
//
//  Created by ZZZ on 2020/12/10.
//

#ifndef ACCAICoverNetServiceProtocol_h
#define ACCAICoverNetServiceProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACCAICoverNetServiceCompletionBlock)( NSNumber * _Nullable index, NSError * _Nullable error);

@protocol ACCAICoverNetServiceProtocol <NSObject>

- (void)fetchAICoverWithZipURI:(nonnull NSString *)zipURI
                    completion:(nullable ACCAICoverNetServiceCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END


#endif /* ACCAICoverNetServiceProtocol_h */
