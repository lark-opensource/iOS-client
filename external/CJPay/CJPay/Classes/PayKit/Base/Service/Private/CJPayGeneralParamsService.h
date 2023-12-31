//
//  CJPayGeneralParamsService.h
//  DouYin
//
//  Created by ByteDance on 2023/3/23.
//

#import "CJPaySDKDefine.h"

#ifndef CJPayGeneralParamsService_h
#define CJPayGeneralParamsService_h

@protocol CJPayGeneralParamsService <NSObject>

- (void)i_getGeneralParamsWithQuery:(NSDictionary *)query delegate:(id<CJPayAPIDelegate>)delegate;

@end

#endif /* CJPayGeneralParamsService_h */
