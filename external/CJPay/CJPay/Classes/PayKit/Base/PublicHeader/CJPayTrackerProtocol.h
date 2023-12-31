//
//  CJPayTrackerProtocol.h
//  Pods
//
//  Created by 王新华 on 3/15/20.
//

#ifndef CJPayTrackerProtocol_h
#define CJPayTrackerProtocol_h

@protocol CJPayTrackerProtocol <NSObject>

/**
 业务打点
 
 @param event 事件名称
 @param params 参数字段 字典形式
 */
- (void)event:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params;

@end

#endif /* CJPayTrackerProtocol_h */
