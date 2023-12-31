//
//  BDLynxNumberKeyListener.h
//  XElement
//
//  Created by zhangkaijie on 2021/6/6.
//

#import "BDXLynxKeyListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxNumberKeyListener : NSObject <BDXLynxKeyListener>

- (NSInteger)getInputType;
- (NSString*)getAcceptedChars;
- (NSString*)filter:(NSString*)source start:(NSInteger)start end:(NSInteger)end dest:(NSString*)dest dstart:(NSInteger)dstart dend:(NSInteger)dend;
- (BOOL)checkCharIsInCharacterSet:(NSString*)characterSet character:(unichar)ch;

@end

NS_ASSUME_NONNULL_END
