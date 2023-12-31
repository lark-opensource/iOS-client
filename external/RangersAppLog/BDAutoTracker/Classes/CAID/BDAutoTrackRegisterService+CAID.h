//
//  BDAutoTrackRegisterService+CAID.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/24.
//

#import "BDAutoTrackRegisterService.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackRegisterService (CAID)
@property (nonatomic, copy) NSString *_Nullable caid;
@property (nonatomic, copy) NSString *_Nullable prevCaid;

- (void)extra_updateParametersWithResponse:(NSDictionary *)responseDic;

- (void)extra_reloadParameters;

- (void)extra_saveAllID;
@end

NS_ASSUME_NONNULL_END
