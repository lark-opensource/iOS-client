//
//  CJPayLoggerProtocol.h
//  Pods
//
//  Created by 王新华 on 3/15/20.
//

#ifndef CJPayLoggerProtocol_h
#define CJPayLoggerProtocol_h

@protocol CJPayLoggerProtocol <NSObject>

/// 日志的方法
/// @param tag 日志标签，发辫快速查找
/// @param content 日志内容
- (void)logInfo:(NSString *)tag content:(NSString *) content;

@end

#endif /* CJPayLoggerProtocol_h */
