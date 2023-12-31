//
//  TSPKMachInfo.h
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import <Foundation/Foundation.h>
#import "TSPKCallStackMacro.h"

@interface TSPKMachInfo : NSObject

@property (nonatomic, assign, nullable) mach_header_t *machHeader;
@property (nonatomic, assign) intptr_t machSlide; // ASLR slide
@property (nonatomic, copy, nullable) NSString * machName;
@property (nonatomic, assign) intptr_t textVMStart;
@property (nonatomic, assign) intptr_t textVMEnd;

- (nonnull instancetype)initWithHeader:(mach_header_t *_Nullable)header
                         slide:(intptr_t)slide
                          name:(const char *_Nullable)name
                         range:(NSRange)range;

- (void)fixSortedRules:(nonnull NSArray *)rules;

@end
