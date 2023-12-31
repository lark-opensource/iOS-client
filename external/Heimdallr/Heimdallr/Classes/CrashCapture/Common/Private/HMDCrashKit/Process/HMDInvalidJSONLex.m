//
//  HMDJSONLex.m
//  Heimdallr
//
//  Created by xuminghao.eric on 2019/11/17.
//

#import "HMDInvalidJSONLex.h"
#import "HMDJSONToken.h"
#import "NSArray+HMDSafe.h"
#import "NSString+HMDSafe.h"

@implementation HMDInvalidJSONLex

- (NSArray *)tokensWithString:(NSString *)jsonString{
    NSMutableArray *tokens = [NSMutableArray new];
    NSInteger index = 0;
    
    char currentChar = '\0';
    while([jsonString hmd_characterAtIndex:index writeToChar:&currentChar]){
        HMDJSONToken *token = nil;
        switch (currentChar) {
            case '{':
                token = [[HMDJSONToken alloc]initWithTokenType:START_OBJ tokenValue:@"{"];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case '}':
                token = [[HMDJSONToken alloc]initWithTokenType:END_OBJ tokenValue:@"}"];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case '[':
                token = [[HMDJSONToken alloc]initWithTokenType:START_ARRAY tokenValue:@"["];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case ']':
                token = [[HMDJSONToken alloc]initWithTokenType:END_ARRAY tokenValue:@"]"];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case ',':
                token = [[HMDJSONToken alloc]initWithTokenType:COMMA tokenValue:@","];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case ':':
                token = [[HMDJSONToken alloc]initWithTokenType:COLON tokenValue:@":"];
                [tokens hmd_addObject:token];
                index += token.tokenLength;
                break;
            case 't':
                if ([self readTrueTokenWithString:jsonString atIndex:index]) {
                    token = [[HMDJSONToken alloc]initWithTokenType:BOOLEAN tokenValue:@"true"];
                    [tokens hmd_addObject:token];
                    index += 4;
                } else {
                    index++;
                }
                break;
            case 'f':
                if([self readFalseTokenWithString:jsonString atIndex:index]){
                    token = [[HMDJSONToken alloc]initWithTokenType:BOOLEAN tokenValue:@"false"];
                    [tokens hmd_addObject:token];
                    index += 5;
                } else {
                    index++;
                }
                break;
            case '"':
                index++;
                {
                    NSString *stringToken = [self readAStringTokenWithString:jsonString atIndex:index];
                    token = [[HMDJSONToken alloc]initWithTokenType:STRING tokenValue:stringToken];
                    [tokens hmd_addObject:token];
                    index += token.tokenLength + 1;
                }
                break;
            default:
                if([self isADigit:currentChar]){
                    NSString *numberToken = [self readANumberTokenWithString:jsonString atIndex:index];
                    token = [[HMDJSONToken alloc]initWithTokenType:NUMBER tokenValue:numberToken];
                    [tokens hmd_addObject:token];
                    index += token.tokenLength;
                } else {
                    index++;
                }
                break;
        }
    }
    return tokens;
}

- (NSString *)readAStringTokenWithString:(NSString *)jsonString atIndex:(NSInteger)startIndex{
    char currentChar = '\0';
    for(NSInteger endIndex = startIndex; ; endIndex++){
        if([jsonString hmd_characterAtIndex:endIndex writeToChar:&currentChar]){
            if(currentChar == '"'){
                return [jsonString hmd_substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
            }
        } else {
            break;
        }
    }
    
    return nil;
}

- (NSString *)readANumberTokenWithString:(NSString *)jsonString atIndex:(NSInteger)startIndex{
    NSString *numberToken = nil;
    NSInteger endIndex = startIndex + 1;
    char currentChar = '\0';
    while([jsonString hmd_characterAtIndex:endIndex writeToChar:&currentChar] && ([self isADigit:currentChar] || currentChar == '.')){
        endIndex++;
    }
    numberToken = [jsonString hmd_substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
    return numberToken;
}

- (BOOL)isADigit:(char)currentChar{
    return (currentChar >= '0' && currentChar <= '9');
}

- (BOOL)readTrueTokenWithString:(NSString *)jsonString atIndex:(NSInteger)startIndex{
    BOOL isTrueValue = false;
    char currentChar = '\0';
    NSInteger index = startIndex;
    if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 't'){
        index++;
        if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'r'){
            index++;
            if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'u'){
                index++;
                if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'e'){
                    isTrueValue = true;
                }
            }
        }
    }
    return isTrueValue;
}

- (BOOL)readFalseTokenWithString:(NSString *)jsonString atIndex:(NSInteger)startIndex{
    BOOL isFalseValue = false;
    char currentChar = '\0';
    NSInteger index = startIndex;
    if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'f'){
        index++;
        if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'a'){
            index++;
            if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'l'){
                index++;
                if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 's'){
                    index++;
                    if([jsonString hmd_characterAtIndex:index writeToChar:&currentChar] && currentChar == 'e'){
                        isFalseValue = true;
                    }
                }
            }
        }
    }
    return isFalseValue;
}

@end
