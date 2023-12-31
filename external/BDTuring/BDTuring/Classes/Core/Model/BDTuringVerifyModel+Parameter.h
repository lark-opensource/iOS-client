//
//  BDTuringVerifyModel+Parameter.h
//  BDTuring
//
//  Created by bob on 2020/7/16.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDTuringParameterModel <NSObject>

+ (__kindof BDTuringVerifyModel *)modelWithParameter:(NSDictionary *)parameter;

@end

@interface BDTuringVerifyModel (Parameter)<BDTuringParameterModel>

@end

NS_ASSUME_NONNULL_END
