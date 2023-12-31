//
//  NSObject+BDTuring.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (BDTuring)

- (nullable NSData *)turing_JSONRepresentationData;
- (nullable NSString *)turing_JSONRepresentation;
- (nullable NSString *)turing_JSONRepresentationForJS;
- (id)turing_safeJsonObject;

@end

NS_ASSUME_NONNULL_END
