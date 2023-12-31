//
//  SGMStatement.h
//  SecGuard
//
//  Created by jianghaowne on 2019/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGMStatement : NSObject

@property (atomic, assign) long useCount;

@property (atomic, retain) NSString *query;

@property (atomic, assign) void *statement;

@property (atomic, assign) BOOL inUse;

- (void)close;
- (void)reset;

@end


NS_ASSUME_NONNULL_END
