//
//  BDXLynxNumberKeyListener.m
//  XElement
//
//  Created by zhangkaijie on 2021/6/6.
//

#import "BDXLynxNumberKeyListener.h"
#import <Foundation/Foundation.h>

@implementation BDXLynxNumberKeyListener

- (instancetype)init {
    self = [super init];
    return self;
}

- (NSInteger)getInputType {
    NSInteger type = TYPE_CLASS_NUMBER;
    return type;
}

- (NSString *)getAcceptedChars {
    // empty implementation
    return @"";
}

- (BOOL)checkCharIsInCharacterSet:(NSString*)characterSet character:(unichar)ch {
    for (int i = (int)[characterSet length] - 1; i >= 0; i--) {
        if (ch == [characterSet characterAtIndex:i]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)filter:(NSString *)source start:(NSInteger)start end:(NSInteger)end dest:(NSString *)dest dstart:(NSInteger)dstart dend:(NSInteger)dend {
    NSMutableString* filteredText = [NSMutableString stringWithString:source];
    NSString* accepted = [self getAcceptedChars];

    if (filteredText != nil) {
        for (int i = (int)[source length] - 1; i >= 0; i--) {
            if (![self checkCharIsInCharacterSet:accepted character:[source characterAtIndex:i]]) {
                [filteredText deleteCharactersInRange:NSMakeRange(i, 1)];
            }
        }
    } else {
        return @"";
    }
    
    return filteredText;
}
@end
