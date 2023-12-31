//
//  HMDJSONToken.h
//  Heimdallr
//
//  Created by xuminghao.eric on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 START_OBJ:'{' ,END_OBJ:'}',
 START_ARRAY:'[', END_ARRAY:']',
 STRING:string, NUMBER:number, BOOLEAN:BOOL,
 COLON:':', COMMA:',', OTHER:space,\n.....
 */
typedef enum{
    START_OBJ, END_OBJ, START_ARRAY, END_ARRAY, STRING, NUMBER, BOOLEAN, COLON, COMMA, OTHER,
} HMDInvalidJSONToken;

@interface HMDJSONToken : NSObject

@property(nonatomic, assign)HMDInvalidJSONToken tokenType;

@property(nonatomic, copy)NSString *tokenValue;

@property(nonatomic, assign)NSInteger tokenLength;

- (instancetype)initWithTokenType:(HMDInvalidJSONToken)tokenType tokenValue:(NSString *)tokenValue;

@end

NS_ASSUME_NONNULL_END
