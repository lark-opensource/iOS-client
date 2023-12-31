//
//  BDXLynxDigitKeyListener.h
//  XElement
//
//  Created by zhangkaijie on 2021/8/31.
//

#import "BDXLynxNumberKeyListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxDigitKeyListener : BDXLynxNumberKeyListener {
    BOOL _decimal;
    BOOL _sign;
}

@property(nonatomic, readonly) NSArray<NSString*>* CHARACTERS;
@property(nonatomic, assign, readwrite) NSString* mDecimalPointChars;
@property(nonatomic, assign, readwrite) NSString* mSignChars;

// init function
- (instancetype)initWithParamsNeedsDecimal:(BOOL)decimal sign:(BOOL)sign;

- (NSInteger)getInputType;
- (NSString*)getAcceptedChars;
- (NSString*)filter:(NSString*)source start:(NSInteger)start end:(NSInteger)end dest:(NSString*)dest dstart:(NSInteger)dstart dend:(NSInteger)dend;

@end

NS_ASSUME_NONNULL_END
