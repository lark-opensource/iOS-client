//
//  LKREWordParser.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREWordParser.h"
#import "LKRENull.h"
#import "LKREFuncNode.h"
#import "LKREConstNode.h"
#import "LKREOperatorNode.h"
#import "LKREIdentifierNode.h"
#import "LKRESplitNode.h"
#import "LKREIdentifierUtil.h"
#import "LKREExprRunner.h"
#import <ByteDanceKit/ByteDanceKit.h>

@implementation LKREWord

- (LKREWord *)initWordWithStr:(NSString *)wordStr line:(NSUInteger)line col:(NSUInteger)col {
    self = [super init];
    if (self) {
        self.wordStr = wordStr;
        self.line = line;
        self.col = col;
    }
    return self;
}

@end

@interface LKREWordParser ()

@property (nonatomic, strong) NSArray *splitWords;

@end

@implementation LKREWordParser

- (instancetype)init {
    self = [super init];
    if (self) {
        self.splitWords = [NSArray arrayWithObjects:@"/**", @"**/",
                          @"->", @"<<", @">>", @"<=", @">=", @"==", @"!=", @"&&", @"||",
                          @"++", @"--",
                          @"+", @"-", @"*", @"/", @"%", @"[", @"]", @"?",
                          @".", @",", @":", @";", @"(", @")", @"{", @"}",
                          @"!", @"<", @">", @"=", @"^", @"~", @"&", @"|",
                          @"null", nil];
    }
    return self;
}

- (NSArray *)splitWord:(NSString *)expr error:(NSError **)error {
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
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | String not closed", NSStringFromSelector(_cmd)]}];
                return nil;
            }
            NSString *tempDealStr = [expr substringWithRange:NSMakeRange(index, range.location - index + 1)];
            NSString *tempResult = @"";
            NSRange tempPoint = [tempDealStr rangeOfString:@"\\"];
            while (tempPoint.location != NSNotFound) {
                tempResult = [NSString stringWithFormat:@"%@%@", tempResult, [tempDealStr substringWithRange:NSMakeRange(0, tempPoint.location)]];
                if (tempPoint.location == tempDealStr.length - 1) {
                    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | \\\\ error in String %@", NSStringFromSelector(_cmd), tempDealStr]}];
                    return nil;
                }
                tempResult = [NSString stringWithFormat:@"%@%@", tempResult, [tempDealStr substringWithRange:NSMakeRange(tempPoint.location, tempPoint.location + 1)]];
                tempDealStr = [tempDealStr substringFromIndex:tempPoint.location + 2];
                tempPoint = [tempDealStr rangeOfString:@"\\"];
            }
            tempResult = [NSString stringWithFormat:@"%@%@", tempResult, tempDealStr];
            [wordArray addObject:[[LKREWord alloc] initWordWithStr:tempResult line:line col:index - currentLineOffset + 1]];
            if (point < index) {
                [wordArray addObject:[[LKREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
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
                [wordArray addObject:[[LKREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
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
                        [wordArray addObject:[[LKREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                                      line:line
                                                                       col:point - currentLineOffset + 1]];
                    }
                    [wordArray addObject:[[LKREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(index, splitLen)]
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
        [wordArray addObject:[[LKREWord alloc] initWordWithStr:[expr substringWithRange:NSMakeRange(point, index - point)]
                                                      line:line
                                                       col:point - currentLineOffset + 1]];
    }
    return wordArray;

}

- (BOOL)checkStringIsNumber:(NSString *)str {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [formatter numberFromString:str];
    if (myNumber != nil) {
        return YES;
    }
    return NO;
}

- (NSArray *)parseWordToNode:(NSArray *)words error:(NSError **)error {
    NSMutableArray *wordNodeArray = [[NSMutableArray alloc] init];
    NSString *tempWord = @"";
    NSUInteger point = 0;
    NSString *originValue = @"";
    LKREWord *tempWordObject = nil;
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
                LKREBaseNode *ln = [wordNodeArray lastObject];
                if ([ln isKindOfClass:[LKREOperatorNode class]] && [((LKREOperatorNode *)ln).aOriginValue isEqualToString:@"-"]) {
                    BOOL isNegativeNumber = false;
                    if (wordNodeArray.count == 1) {
                        isNegativeNumber = true;
                    } else {
                        LKREBaseNode *pren = [wordNodeArray objectAtIndex:wordNodeArray.count - 2];
                        if ([pren isKindOfClass:[LKREOperatorNode class]] ||
                            [pren isKindOfClass:[LKRECenterSplitNode class]] ||
                            [pren isKindOfClass:[LKRELeftSplitNode class]]) {
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
            if (!objectValue) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRUNKNOWN_CAUSE userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Fail to parse value: '%@' to number", NSStringFromSelector(_cmd), tempWord]}];
                return nil;
            }
            [wordNodeArray addObject:[[LKREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if (firstChar == '"') {
            if (lastChar != '"' || tempWord.length < 2) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | String not closed %@", NSStringFromSelector(_cmd), tempWord]}];
                return nil;
            }
            tempWord = [tempWord substringWithRange:NSMakeRange(1, tempWord.length - 2)];
            objectValue = tempWord;
            [wordNodeArray addObject:[[LKREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if (firstChar == '\'') {
            if (lastChar != '\'' || tempWord.length < 2) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | String not closed %@", NSStringFromSelector(_cmd), tempWord]}];
                return nil;
            }
            tempWord = [tempWord substringWithRange:NSMakeRange(1, tempWord.length - 2)];
            objectValue = tempWord;
            [wordNodeArray addObject:[[LKREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if ([tempWord isEqualToString:@"true"] || [tempWord isEqualToString:@"false"]) {
            objectValue = [NSNumber numberWithBool:[tempWord boolValue]];
            [wordNodeArray addObject:[[LKREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else if ([tempWord isEqualToString:@"null"]) {
            objectValue = [LKRENull new];
            [wordNodeArray addObject:[[LKREConstNode alloc] initWithConstValue:objectValue originValue:originValue index:point]];
            point += 1;
        } else {
            LKREOperator *op = [[LKREOperatorManager sharedManager] getOperatorFromSymbol:tempWord];
            if (op != nil) {
                [wordNodeArray addObject:[[LKREOperatorNode alloc] initWithOperatorValue:op originValue:originValue index:point]];
            } else {
                if ([tempWord isEqualToString:@"("]) {
                    LKRELeftSplitNode *lsn = [[LKRELeftSplitNode alloc] initAsSplitNode:originValue index:point];
                    if (wordNodeArray.count > 0) {
                        LKREBaseNode *lastNode = [wordNodeArray lastObject];
                        if ([lastNode isKindOfClass:[LKREIdentifierNode class]]) {
                            [wordNodeArray removeLastObject];
                            LKREIdentifierNode *idn = (LKREIdentifierNode *)lastNode;
                            LKREFunc *fc = [[LKREFuncManager sharedManager] getFuncFromSymbol:idn.identifier];
                            if (fc == nil) {
                                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRUNKNOWN_FUNCTION userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | invald func %@", NSStringFromSelector(_cmd), idn.identifier]}];
                                return nil;
                            }
                            [wordNodeArray addObject:[[LKREFuncNode alloc] initWithFuncValue:fc originValue:originValue index:point]];
                            lsn.isFunctionStart = true;
                        }
                    }
                    [wordNodeArray addObject:lsn];
                } else if ([tempWord isEqualToString:@"{"]) {
                    LKREFunc *arrayFc = [[LKREFuncManager sharedManager] getFuncFromSymbol:@"array"];
                    [wordNodeArray addObject:[[LKREFuncNode alloc] initWithFuncValue:arrayFc originValue:originValue index:point]];
                    LKRELeftSplitNode *lsN =  [[LKRELeftSplitNode alloc] initAsSplitNode:originValue index:point];
                    lsN.isFunctionStart = true;
                    [wordNodeArray addObject:lsN];
                } else if ([tempWord isEqualToString:@")"] || [tempWord isEqualToString:@"}"]) {
                    [wordNodeArray addObject:[[LKRERightSplitNode alloc] initAsSplitNode:originValue index:point]];
                } else if ([tempWord isEqualToString:@","]) {
                    [wordNodeArray addObject:[[LKRECenterSplitNode alloc] initAsSplitNode:originValue index:point]];
                } else if ([LKREIdentifierUtil isValidIdentifier:tempWord]) {
                    [wordNodeArray addObject:[[LKREIdentifierNode alloc] initWithIdentifierValue:tempWord originValue:originValue index:point]];
                } else if ([tempWord isEqualToString:@"["]) {
                    [wordNodeArray addObject:[[LKRELeftSplitNode alloc] initAsSplitNode:originValue index:point]];
                } else if ([tempWord isEqualToString:@"]"]) {
                    //last word must be a IdentifierNode, and before must be a LeftSplitNode. Otherwise, the express has an error.
                    LKREBaseNode *lastNode = [wordNodeArray lastObject];
                    LKREBaseNode *beforeLastNode = [wordNodeArray btd_objectAtIndex:wordNodeArray.count-2];
                    if ([lastNode isKindOfClass:[LKREIdentifierNode class]] && [beforeLastNode isKindOfClass:[LKRELeftSplitNode class]]) {
                        [wordNodeArray btd_removeObject:beforeLastNode];
                    } else {
                        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | invalid ']', it must contain an/only one variable at left, and closed by '['", NSStringFromSelector(_cmd)]}];
                        return nil;
                    }
                } else {
                    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_IDENTIFIER userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | invalid identifier %@", NSStringFromSelector(_cmd), tempWord]}];
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
