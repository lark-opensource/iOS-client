//  Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXGETUIRESULTDARWIN_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXGETUIRESULTDARWIN_H_

#import <Foundation/Foundation.h>

@interface LynxGetUIResultDarwin : NSObject

@property(nonatomic, readonly) NSArray *uiArray;
@property(nonatomic, readonly) int errCode;
@property(nonatomic, readonly) NSString *errMsg;

- (instancetype)init:(NSArray *)ui errCode:(int)err errMsg:(NSString *)msg;

@end

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXGETUIRESULTDARWIN_H_
