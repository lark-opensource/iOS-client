//
//  BDREWordParser.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREWordParser.h"
#import "BDRENull.h"
#import "BDREFuncNode.h"
#import "BDREConstNode.h"
#import "BDREOperatorNode.h"
#import "BDREIdentifierNode.h"
#import "BDRESplitNode.h"
#import "BDREIdentifierUtil.h"
#import "BDREExprRunner.h"

@implementation BDREWord

- (instancetype)initWordWithStr:(NSString *)wordStr line:(NSUInteger)line col:(NSUInteger)col {
    self = [super init];
    if (self) {
        self.wordStr = wordStr;
        self.line = line;
        self.col = col;
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get word : [%@], [%ld], [%ld]", wordStr, line, col];
        }];
    }
    return self;
}

@end

@implementation BDREWordParser

+ (NSArray *)splitWords {
    static NSArray *words;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        words = @[@"/**", @"**/",
                  @"->", @"<<", @">>", @"<=", @">=", @"==", @"!=", @"&&", @"||",
                  @"++", @"--",
                  @"+", @"-", @"*", @"/", @"%", @"[", @"]", @"?",
                  @".", @",", @":", @";", @"(", @")", @"{", @"}",
                  @"!", @"<", @">", @"=", @"^", @"~", @"&", @"|",
                  @"null"];
    });
    return words;
}

+ (NSArray *)splitWord:(NSString *)expr error:(NSError *__autoreleasing  _Nullable *)error
{
    NSMutableArray *wordArray = [[NSMutableArray alloc] init];
    
    NSString *singleChar;
    NSUInteger exprLength = expr.length;
    NSUInteger line = 1;
    NSUInteger index = 0;
    NSUInteger point = 0;
    NSUInteger currentLineOffset = 0;
    while (index < exprLength) {
        singleChar = [expr substringWithRange:NSMakeRange(index, 1)];
        if ([singleChar isEqualToString:@"\""] || [singleChar isEqualToString:@"'"]) {
            NSRange range = [expr rangeOfString:singleChar options:NSLiteralSearch range:NSMakeRange(index + 1, exprLength - index - 1)];
            while (range.location != NSNotFound && [[expr substringWithRange:NSMakeRange(range.location - 1, 1)] isEqualToString:@"\\"]) {
                range = [expr rangeOfString:singleChar options:NSLiteralSearch range:NSMakeRange(range.location + 1, exprLength - range.location - 1)];
            }
            if (range.location == NSNotFound) {
                if (error) {
                    *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | String not closed", NSStringFromSelector(_cmd)] ?: @""}];
                }
                return nil;
            }
            NSString *tempDealStr = [expr substringWithRange:NSMakeRange(index, range.location - index + 1)];
            NSString *tempResult = @"";
            NSRange tempPoint = [tempDealStr rangeOfString:@"\\"];
            while (tempPoint.location != NSNotFound) {
                tempResult = [NSString stringWithFormat:@"%@%@", tempResult, [tempDealStr substringWithRange:NSMakeRange(0, tempPoint.location)]];
                if (tempPoint.location == tempDealStr.length - 1) {
                    if (error) {
                        *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | \\\\ error in String %@", NSStringFromSelector(_cmd), tempDealStr] ?: @""}];
                    }
                    return nil;
                }
                tempResult = [NSString stringWithFormat:@"%@%@", tempResult, [tempDealStr substringWithRange:NSMakeRange(tempPoint.location + 1, 1)]];
                tempDealStr = [tempDealStr substringFromIndex:tempPoint.location + 2];
                tempPoint = [tempDealStr rangeOfString:@"\\"];
            }
            tempResult = [NSString stringWithFormat:@"%@%@", tempResult, tempDealStr];
            [wordArray addObject:[[BDREWord alloc] initWordWithStr:tempResult line:line col:index - currentLineOffset + 1]];
            if (point < index) {
                [wordArray addObject:[[BDREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                              line:line
                                                               col:point - currentLineOffset + 1]];
            }
            index = range.location + 1;
            point = index;
        } else if ([singleChar isEqualToString:@"."] &&
                   point < index &&
                   [self checkStringIsNumber:[expr substringWithRange:NSMakeRange(point, index - point)]]) {
            index += 1;
        } else if ([singleChar isEqualToString:@" "] ||
                   [singleChar isEqualToString:@"\r"] ||
                   [singleChar isEqualToString:@"\n"] ||
                   [singleChar isEqualToString:@"\t"] ||
                   [singleChar isEqualToString:@"\f"] ||
                   [singleChar isEqualToString:@"\u00a0"]) {
            if (point < index) {
                [wordArray addObject:[[BDREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                              line:line
                                                               col:point - currentLineOffset + 1]];
            }
            if ([singleChar isEqualToString:@"\n"]) {
                line += 1;
                currentLineOffset = index + 1;
            }
            index += 1;
            point = index;
        } else {
            BOOL isFind = false;
            for (NSString *splitw in self.splitWords) {
                NSUInteger splitLen = splitw.length;
                if (index + splitLen <= exprLength && [[expr substringWithRange:NSMakeRange(index, splitLen)] isEqualToString:splitw]) {
                    if (point < index) {
                        [wordArray addObject:[[BDREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                                      line:line
                                                                       col:point - currentLineOffset + 1]];
                    }
                    [wordArray addObject:[[BDREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(index, splitLen)]
                                                                  line:line
                                                                   col:index - currentLineOffset + 1]];
                    index += splitLen;
                    point = index;
                    isFind = true;
                    break;
                }
            }
            if(!isFind) {
                index += 1;
            }
        }
    }
    if (point < index) {
        [wordArray addObject:[[BDREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                      line:line
                                                       col:point - currentLineOffset + 1]];
    }
    return wordArray;

}

+ (BOOL)checkStringIsNumber:(NSString *)str {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [formatter numberFromString:str];
    if (myNumber != nil) {
        return YES;
    }
    return NO;
}

+ (NSArray *)parseWordToNode:(NSArray *)words error:(NSError *__autoreleasing  _Nullable *)error
{
    NSMutableArray *wordNodeArray = [[NSMutableArray alloc] init];
    NSString *tempWord = @"";
    NSUInteger point = 0;
    NSString *originValue = @"";
    BDREWord *tempWordObject = nil;
    id objectValue = nil;
    
    while (point < words.count) {
        tempWordObject = words[point];
        tempWord = tempWordObject.wordStr;
        originValue = [tempWord stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        char firstChar = [tempWord characterAtIndex:0];
        char lastChar = [tempWord characterAtIndex:tempWord.length - 1];
        lastChar = tolower(lastChar);
        if (firstChar >= '0' && firstChar <= '9') {
            if (wordNodeArray.count > 0) {
                BDREBaseNode *ln = [wordNodeArray lastObject];
                if ([ln isKindOfClass:[BDREOperatorNode class]] && [((BDREOperatorNode *)ln).aOriginValue isEqualToString:@"-"]) {
                    BOOL isNegativeNumber = false;
                    if (wordNodeArray.count == 1) {
                        isNegativeNumber = true;
                    } else {
                        BDREBaseNode *pren = [wordNodeArray objectAtIndex:wordNodeArray.count - 2];
                        if ([pren isKindOfClass:[BDREOperatorNode class]] ||
                            [pren isKindOfClass:[BDRECenterSplitNode class]] ||
                            [pren isKindOfClass:[BDRELeftSplitNode class]]) {
                            isNegativeNumber = true;
                        }
                    }
                    if (isNegativeNumber) {
                        [wordNodeArray removeLastObject];
                        tempWord = [NSString stringWithFormat:@"%@%@", @"-", tempWord];
                    }
                }
            }
            
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            if (lastChar == 'd') {
                tempWord = [tempWord substringWithRange:NSMakeRange(0, tempWord.length - 1)];
                objectValue = [NSNumber numberWithDouble:[tempWord doubleValue]];
            } else if (lastChar == 'f') {
                tempWord = [tempWord substringWithRange:NSMakeRange(0, tempWord.length - 1)];
                objectValue = [NSNumber numberWithDouble:[tempWord floatValue]];
            } else if (lastChar == '.') {
                tempWord = [tempWord substringWithRange:NSMakeRange(0, tempWord.length)];
                objectValue = [NSNumber numberWithDouble:[tempWord doubleValue]];
            } else if (lastChar == 'l') {
                tempWord = [tempWord substringWithRange:NSMakeRange(0, tempWord.length - 1)];
                objectValue = [NSNumber numberWithDouble:[tempWord longLongValue]];
            } else {
                objectValue = [numberFormatter numberFromString:tempWord];
            }
            
            [wordNodeArray addObject:[[BDREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if (firstChar == '"') {
            if (lastChar != '"' || tempWord.length < 2) {
                if (error) {
                    *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | String not closed %@", NSStringFromSelector(_cmd), tempWord] ?: @""}];
                }
                return nil;
            }
            tempWord = [tempWord substringWithRange:NSMakeRange(1, tempWord.length - 2)];
            objectValue = tempWord;
            [wordNodeArray addObject:[[BDREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if (firstChar == '\'') {
            if (lastChar != '\'' || tempWord.length < 2) {
                if (error) {
                    *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | String not closed %@", NSStringFromSelector(_cmd), tempWord] ?: @""}];
                }
                return nil;
            }
            tempWord = [tempWord substringWithRange:NSMakeRange(1, tempWord.length - 2)];
            objectValue = tempWord;
            [wordNodeArray addObject:[[BDREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if ([tempWord isEqualToString:@"true"] || [tempWord isEqualToString:@"false"]) {
            objectValue = [NSNumber numberWithBool:[tempWord boolValue]];
            [wordNodeArray addObject:[[BDREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if ([tempWord isEqualToString:@"null"]) {
            objectValue = [BDRENull new];
            [wordNodeArray addObject:[[BDREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else {
            BDREOperator *op = [[BDREOperatorManager sharedManager] getOperatorFromSymbol:tempWord];
            if (op != nil) {
                [wordNodeArray addObject:[[BDREOperatorNode alloc] initWithOperatorValue:op originValue:originValue index:point]];
            } else {
                if ([tempWord isEqualToString:@"("]) {
                    BDRELeftSplitNode *lsn = [[BDRELeftSplitNode alloc] initAsSplitNode:originValue index:point];
                    if (wordNodeArray.count > 0) {
                        BDREBaseNode *lastNode = [wordNodeArray lastObject];
                        if ([lastNode isKindOfClass:[BDREIdentifierNode class]]) {
                            [wordNodeArray removeLastObject];
                            BDREIdentifierNode *idn = (BDREIdentifierNode *)lastNode;
                            BDREFunc *fc = [[BDREFuncManager sharedManager] getFuncFromSymbol:idn.identifier];
                            [wordNodeArray addObject:[[BDREFuncNode alloc] initWithFuncName:idn.identifier func:fc originValue:originValue index:point]];
                            lsn.isFunctionStart = true;
                        }
                    }
                    [wordNodeArray addObject:lsn];
                } else if ([tempWord isEqualToString:@"["]) {
                    BDREFunc *arrayFc = [[BDREFuncManager sharedManager] getFuncFromSymbol:@"array"];
                    [wordNodeArray addObject:[[BDREFuncNode alloc] initWithFuncName:@"array" func:arrayFc originValue:originValue index:point]];
                    BDRELeftSplitNode *lsN =  [[BDRELeftSplitNode alloc] initAsSplitNode:originValue index:point];
                    lsN.isFunctionStart = true;
                    [wordNodeArray addObject:lsN];
                } else if ([tempWord isEqualToString:@")"] || [tempWord isEqualToString:@"]"]) {
                    [wordNodeArray addObject:[[BDRERightSplitNode alloc] initAsSplitNode:originValue index:point]];
                } else if ([tempWord isEqualToString:@","]) {
                    [wordNodeArray addObject:[[BDRECenterSplitNode alloc] initAsSplitNode:originValue index:point]];
                } else if ([BDREIdentifierUtil isValidIdentifier:tempWord]) {
                    [wordNodeArray addObject:[[BDREIdentifierNode alloc] initWithIdentifierValue:tempWord originValue:originValue index:point]];
                } else {
                    if (error) {
                        *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | invalid identifier %@", NSStringFromSelector(_cmd), tempWord] ?: @""}];
                    }
                    return nil;
                }
            }
            point += 1;
        }
        originValue = nil;
    }
    return  wordNodeArray;
}

@end
