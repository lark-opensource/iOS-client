//
//  CJPaySecService.h
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/23.
//

#ifndef CJPaySecSevice_h
#define CJPaySecSevice_h

@protocol CJPaySecService <NSObject>

- (void)start;
- (void)enterScene:(NSString *)scene;
- (void)leaveScene:(NSString *)scene;
- (NSDictionary *)buildSafeInfo:(NSDictionary *)info context:(NSDictionary *)context;

@end

#endif /* CJPaySecSevice_h */
