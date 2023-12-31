//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "KryptonLLog.h"

void _KryptonLogInternal(LynxLogLevel level, NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  NSString *log = [@"[Krypton] " stringByAppendingString:message];
  _LynxLogInternal(level, log, @"");
}
