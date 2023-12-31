//
//  BDAccountSealResult+Creator.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDAccountSealResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAccountSealResult (Creator)

@property (nonatomic, assign) BDAccountSealResultCode resultCode;

/// those properties just in case you want it
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, copy, nullable) NSDictionary *extraData;

@end

NS_ASSUME_NONNULL_END
