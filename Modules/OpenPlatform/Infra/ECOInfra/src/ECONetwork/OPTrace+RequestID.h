//
//  OPTrace+RequestID.h
//  ECOProbe
//
//  Created by MJXin on 2021/4/9.
//

#import <ECOProbe/OPTrace.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPTrace (RequestID)
- (void)genRequestID:(NSString *)source;
- (nullable  NSString *)getRequestID;
@end

NS_ASSUME_NONNULL_END
