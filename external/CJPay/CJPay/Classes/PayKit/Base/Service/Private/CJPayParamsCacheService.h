//
//  CJPayParamsCacheService.h
//  CJPaySandBox
//
//  Created by 高航 on 2022/12/2.
//

#ifndef CJPayParamsCacheService_h
#define CJPayParamsCacheService_h

@protocol CJPayParamsCacheService <NSObject>

- (NSString *)i_getParamsFromCache:(NSString *)key;

- (BOOL)i_setParams:(NSString *)params key:(NSString *)key;

@end

#endif /* CJPayParamsCacheService_h */

