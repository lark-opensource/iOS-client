//
//  BDTuringConfig+Parameters.h
//  BDTuring
//
//  Created by bob on 2019/12/26.
//

#import "BDTuringConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyModel;

@interface BDTuringConfig (Parameters)

@property (nonatomic, weak) BDTuringVerifyModel *model;

- (NSMutableDictionary *)commonWebURLQueryParameters;
- (NSMutableDictionary *)eventParameters;
- (NSMutableDictionary *)turingWebURLQueryParameters;

- (NSMutableDictionary *)requestQueryParameters;
- (NSMutableDictionary *)requestPostParameters;

- (NSMutableDictionary *)twiceVerifyRequestQueryParameters;

- (NSString *)stringFromDelegateSelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
