//
//  BDTuringSMSModel.h
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

/// only for send sms code and verify sms code
@interface BDTuringSMSModel : BDTuringVerifyModel

@property (nonatomic, copy) NSString *requestURL;
@property (nonatomic, assign) NSInteger scene;
@property (nonatomic, copy) NSString *mobile;

- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
