//
//  BDTuringSMSCodeResult.h
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuringVerifyResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringSMSCodeResult : BDTuringVerifyResult

@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, copy, nullable) NSString *ticket;

@end

NS_ASSUME_NONNULL_END
