//
//  SGMDataBase.h
//  SecGuard
//
//  Created by jianghaowne on 2019/5/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SGMResultSet;

@interface SGMDataBase : NSObject

- (instancetype)initWithPath:(NSString *)path;

- (BOOL)open;

- (NSError *)lastError;

- (BOOL)executeUpdate:(NSString*)sql, ...;
- (SGMResultSet *)executeQuery:(NSString*)sql, ...;

@end

NS_ASSUME_NONNULL_END
