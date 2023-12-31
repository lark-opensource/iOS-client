//
//  BDTuring+InHouse.h
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const BDTuringBOEURLPicture;
FOUNDATION_EXTERN NSString *const BDTuringBOEURLSMS;
FOUNDATION_EXTERN NSString *const BDTuringBOEURLQA;
FOUNDATION_EXTERN NSString *const BDTuringBOEURLSeal;
FOUNDATION_EXPORT NSString *const BDTuringBOEURLAutoVerify;
FOUNDATION_EXPORT NSString *const BDTuringBOEURLFullAutoVerify;


@interface BDTuring (InHouse)

+ (nullable NSDictionary *)inhouseCustomValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
