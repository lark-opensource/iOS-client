//
//  BDXLynxDialerKeyListener.m
//  XElement
//
//  Created by zhangkaijie on 2021/6/7.
//

#import "BDXLynxNumberKeyListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxDialerKeyListener : BDXLynxNumberKeyListener

@property(nonatomic, readonly) NSArray<NSString*>* CHARACTERS;

- (NSInteger)getInputType;
- (NSString*)getAcceptedChars;

@end

NS_ASSUME_NONNULL_END
