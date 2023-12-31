//
//  CJPayProtocolViewService.h
//  DouYin
//
//  Created by ByteDance on 2023/3/25.
//

#ifndef CJPayProtocolViewService_h
#define CJPayProtocolViewService_h

typedef void(^CJPayProtocolCallBack)(void);

@protocol CJPayProtocolViewService <NSObject>

- (void)i_showProtocolDetail:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end

#endif /* CJPayProtocolViewService_h */
