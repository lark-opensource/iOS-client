//
//  BDTuringSettings+Report.h
//  BDTuring
//
//  Created by bob on 2020/4/9.
//

#import "BDTuringSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringSettings (Report)

@property (nonatomic, assign) long long startRequestTime;

- (void)reportRequestResult:(NSInteger)result;

@end

NS_ASSUME_NONNULL_END
