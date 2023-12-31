//
//  BytedCertError.m
//  BytedCertSDK
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#import "BytedCertError.h"
#import "BDCTEventTracker.h"
#import "BDCTLocalization.h"
#import "BDCTStringConst.h"
#import <BDModel/BDModel.h>
#import <ByteDanceKit/ByteDanceKit.h>

#define TONUM(x) [NSNumber numberWithUnsignedInteger:x]


@interface BytedCertError ()
@property (nonatomic, assign, readwrite) NSInteger errorCode;
@property (nonatomic, assign, readwrite) NSInteger detailErrorCode;

@property (nonatomic, copy, readwrite) NSString *errorMessage;
@property (nonatomic, copy, readwrite) NSString *detailErrorMessage;

@property (nonatomic, strong, readwrite) NSError *oriError;
@end


@implementation BytedCertError

- (instancetype)initWithType:(BytedCertErrorType)errorType {
    return [self initWithType:errorType oriError:nil];
}

- (instancetype)initWithType:(BytedCertErrorType)errorType detailErrorCode:(NSInteger)detailErrorCode {
    return [self initWithType:errorType oriError:[NSError errorWithDomain:@"" code:detailErrorCode userInfo:nil]];
}

- (instancetype)initWithType:(BytedCertErrorType)errorType oriError:(NSError *)error {
    return [self initWithType:errorType errorMsg:nil oriError:error];
}

- (instancetype)initWithType:(BytedCertErrorType)errorCode errorMsg:(NSString *)errorMsg oriError:(NSError *)error {
    if (self = [super init]) {
        _errorCode = errorCode;
        _errorMessage = errorMsg ?: [bdct_error_code_to_message() btd_stringValueForKey:@(errorCode)];
        if (error) {
            _detailErrorCode = error.code;
            _detailErrorMessage = error.localizedDescription ?: error.description; // TODO: 联调看下
        } else {
            _detailErrorCode = _errorCode;
            _detailErrorMessage = _errorMessage;
        }
        [BDCTEventTracker trackError:self];
    }
    return self;
}

- (NSString *)description {
    return [self bd_modelToJSONString];
}

@end
