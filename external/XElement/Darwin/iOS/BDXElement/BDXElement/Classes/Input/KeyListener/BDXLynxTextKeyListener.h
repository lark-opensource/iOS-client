//
//  BDXLynxTextKeyListener.h
//  XElement
//
//  Created by zhangkaijie on 2021/6/7.
//

#import "BDXLynxKeyListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxTextKeyListener : NSObject <BDXLynxKeyListener>

- (NSInteger)getInputType;
- (NSString*)filter:(NSString*)source start:(NSInteger)start end:(NSInteger)end dest:(NSString*)dest dstart:(NSInteger)dstart dend:(NSInteger)dend;

@end

NS_ASSUME_NONNULL_END
