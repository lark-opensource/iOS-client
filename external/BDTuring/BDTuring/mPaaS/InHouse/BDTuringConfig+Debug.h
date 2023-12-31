//
//  BDTuringConfig+Debug.h
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuringConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringConfig (Debug)

/**
 just for test
 */
- (void)setPictureURL:(nullable NSString *)requestURL;
- (void)setSMSURL:(nullable NSString *)requestURL;
- (void)setQAURL:(nullable NSString *)requestURL;
- (void)setSealURL:(nullable NSString *)requestURL;
- (void)setAutoVerifyURL:(nullable NSString *)requestURL;
- (void)setFullAutoVerifyURL:(nullable NSString *)requestURL;

@end

NS_ASSUME_NONNULL_END
