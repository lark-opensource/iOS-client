//
//  BDTuringParameterVerifyModel.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyModel.h"
#import "BDTuringParameter.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringParameterVerifyModel : BDTuringVerifyModel<BDTuringVerifyModelCreator>

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSDictionary *verifyData;
@property (nonatomic, strong) BDTuringVerifyModel *actualModel;

@end

NS_ASSUME_NONNULL_END
