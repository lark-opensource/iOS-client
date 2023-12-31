//
//  HMDInvalidThreadsJSONParser.m
//  Heimdallr
//
//  Created by xuminghao.eric on 2019/11/17.
//

#import "HMDInvalidThreadsJSONParser.h"
#import "HMDInvalidJSONLex.h"
#import "HMDJSONToken.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"

static NSString *const kCrash = @"crashed";
static NSString *const kRegister = @"register";
static NSString *const kStackTrace = @"stacktrace";
static NSString *const kDispatchName = @"dispatch_name";
static NSString *const kCompletedStackTraceFlag = @"completedStackTrace";

@implementation HMDInvalidThreadsJSONParser

- (NSDictionary *)parseInvalidThreadsJSONWithFile:(NSString *)jsonFilePath{
    NSString *jsonString = nil;
    jsonString = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:nil];
    return [self parseInvalidThreadsJSONWithString:jsonString];
}

- (NSDictionary *)__attribute__((annotate("oclint:suppress[clang-static-analyze]"))) parseInvalidThreadsJSONWithString:(NSString *)jsonString{
    NSDictionary *threadsDictionary = nil;
    NSMutableArray *threads = [NSMutableArray new];
    BOOL currentThreadCrashed = false;
    BOOL existThreadCrashed = false;
    
    //词法分析
    HMDInvalidJSONLex *lex = [[HMDInvalidJSONLex alloc]init];
    NSArray<HMDJSONToken *> *tokens = [lex tokensWithString:jsonString];
    NSInteger countOfTokens = [tokens count];
    NSInteger indexOfTokens = 0;
    
    //语法分析
    while(indexOfTokens < countOfTokens){
        HMDJSONToken *currentToken = [tokens hmd_objectAtIndex:indexOfTokens];
        
        if(currentToken.tokenType == STRING){
            if([currentToken.tokenValue isEqualToString:kCrash]){
                currentThreadCrashed = true;
                existThreadCrashed = true;
                indexOfTokens++;
            } else if([currentToken.tokenValue isEqualToString:kStackTrace]){
//当遍历到tokenValue等于”stacktrace“的Token时开始读取stacktrace，stacktrace示例："stacktrace":[544844184,545533421,545537177,38517013,38568471,38426481,38426229,38426885,38513215,38513027,545536091,545535951,545527588]
                indexOfTokens += 2;     //此时index的位置在'['
                NSArray *stackTrace = [self stackTraceWithTokens:tokens atIndex:(indexOfTokens + 1)];
                Boolean completedStackTrace = false;      //标识stacktrace是否完整
                indexOfTokens += [stackTrace count] * 2;     //每个address后面是一个','，最后一个address后面没有','，跳过这些Token
                HMDJSONToken *afterStackTraceToken = [tokens hmd_objectAtIndex:indexOfTokens];
                if(afterStackTraceToken.tokenType == END_ARRAY){     //如果接下来的Token是']'则说明stacktrace是完整的
                    completedStackTrace = true;
                    indexOfTokens++;
                }
                
                NSMutableDictionary *thread = [NSMutableDictionary new];
                if(completedStackTrace){
                    if(currentThreadCrashed){             //如果是crashed线程，则设置一个kCrash
                        [thread hmd_setSafeObject:[NSNumber numberWithBool:true] forKey:kCrash];
                        currentThreadCrashed = false;
                    }
                    
                    [thread setValue:nil forKey:kRegister];
                    [thread hmd_setSafeObject:stackTrace forKey:kStackTrace];
                    [threads hmd_addObject:thread];
                } else {
                    if(currentThreadCrashed){         //如果crashed线程不完整，则直接退出
                        existThreadCrashed = false;
                        break;
                    }
                }
            } else {
                indexOfTokens++;
            }
        } else {      //不是STRING类型的Token都先跳过
            indexOfTokens++;
        }
    }
    
    //如果出现过crashed线程且stackTrace完整
    if(existThreadCrashed){
        threadsDictionary = [NSDictionary hmd_dictionaryWithObject:threads forKey:@"threads"];
    }
    HMDLog(@"%@", threadsDictionary);
    return threadsDictionary;
}

- (NSArray *)stackTraceWithTokens:(NSArray<HMDJSONToken *> *)tokens atIndex:(NSInteger)index{
    NSMutableArray *stackTrace = [NSMutableArray new];
    NSInteger countOfTokens = [tokens count];
    while(index < countOfTokens){
        HMDJSONToken *currentToken = [tokens hmd_objectAtIndex:index];
        if(currentToken.tokenType == NUMBER){
            [stackTrace hmd_addObject:[NSNumber numberWithLong:[currentToken.tokenValue integerValue]]];
            index++;
        } else if(currentToken.tokenType == COMMA){
            index++;
        } else {
            break;
        }
    }
    return stackTrace;
}

@end
