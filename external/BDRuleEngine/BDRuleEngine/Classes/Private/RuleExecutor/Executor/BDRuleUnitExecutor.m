//
//  BDRuleUnitExecutor.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//

#import "BDRuleUnitExecutor.h"
#import "BDREExprRunner.h"

@interface BDRuleUnitExecutor()

@property (nonatomic, copy, nonnull) NSString *cel;
@property (nonatomic, strong, nullable) NSArray *commands;
@property (nonatomic, strong, nullable) id<BDREExprEnv> env;
@property (nonatomic, copy) NSString *uuid;

@end

@implementation BDRuleUnitExecutor

- (instancetype)initWithCel:(NSString *)cel
                   commands:(NSArray *)commands
                        env:(id<BDREExprEnv>)env
                       uuid:(nonnull NSString *)uuid
{
    self = [super init];
    if (self) {
        _cel = cel;
        _commands = commands;
        _env = env;
        _uuid = uuid;
    }
    return self;
}

- (BOOL)evaluate:(NSError *__autoreleasing  _Nullable *)error
{
    BDREExprResponse *response = [[BDREExprRunner sharedRunner] execute:_cel preCommands:_commands withEnv:_env uuid:_uuid];
    
    if (!response.error) {
        if ([response.result isKindOfClass:[NSNumber class]]) {
            return [response.result boolValue];
        } else {
            if (error) {
                *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRRESVALUE_NOTNUM userInfo:@{NSLocalizedDescriptionKey: @"result is not nsnumber"}];
            }
        }
    } else {
        if (error) {
            *error = response.error;
        }
    }
    
    return NO;
 }
@end
