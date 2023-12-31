//
//  NSExceptionCatcher.h
//  LarkMedia
//
//  Created by fakegourmet on 2023/3/7.
//

#import <Foundation/Foundation.h>

#ifndef NSExceptionCatcher_h
#define NSExceptionCatcher_h

typedef void(^NSExceptionExecution)(void);

@interface NSExceptionCatcher : NSObject

+(NSException* _Nullable) tryCatch: (NSExceptionExecution _Nonnull)execution;

@end

#endif /* NSExceptionCatcher_h */
