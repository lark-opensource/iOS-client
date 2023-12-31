//
//  OPArguement.m
//  OPSDK
//
//  Created by Nicholas Tau on 2020/12/10.
//

#import "OPArguement.h"
#import <objc/runtime.h>

@interface OPArguement()
@property (nonatomic, copy, readwrite) NSString *name;
@end

@implementation OPArguement
- (instancetype)initWithType:(NSString *)type
                 nullability:(OPNullability)nullability
                      unused:(BOOL)unused
{
  if (self = [super init]) {
    _type = [type copy];
    _nullability = nullability;
    _unused = unused;
  }
  return self;
}
@end

NSString *OPParseMethodSignature(const char *input, NSArray<OPArguement *> **arguments)
{
    //TODO parse all arguements to argurment list dynamically
    return @"";
}

SEL selectorForType(NSString *type)
{
    return nil;
}
