//
//  BDALogProtocolHelperA.hpp
//  BDALog
//
//  Created by liuhan on 2023/5/6.
//

#ifndef BDALogProtocolHelperA_hpp
#define BDALogProtocolHelperA_hpp


#include <stdio.h>
#import <Foundation/Foundation.h>

/* -------------------------------BDALOGPROTOCOL调用----------------------------------------*/


typedef void(alog_protocol_write_var_func_ptr)(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, va_list args);

typedef void(alog_protocol_write_func_ptr)(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format);

typedef void(alog_protocol_write_oc_func_ptr)(const char *_filename, const char *_func_name, NSString const *_tag, int _level, int _line, NSString const * _format);


@interface BDALogProtocolHelper : NSObject

@end

#endif /* BDALogProtocolHelperA_hpp */
