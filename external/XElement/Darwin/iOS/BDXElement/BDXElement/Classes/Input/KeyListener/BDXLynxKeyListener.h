//
//  BDXLynxKeyListener.h
//  XElement
//
//  Created by zhangkaijie on 2021/6/6.
//

#import <Foundation/Foundation.h>
#import "InputType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLynxKeyListener <NSObject>

@required
- (NSInteger)getInputType;
@required
- (NSString*)filter:(NSString*)source start:(NSInteger)start end:(NSInteger)end dest:(NSString*)dest dstart:(NSInteger)dstart dend:(NSInteger)dend;

@end

NS_ASSUME_NONNULL_END
