//
//  BDAccountSealResult.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDAccountSealResult.h"

@interface BDAccountSealResult ()

@property (nonatomic, assign) BDAccountSealResultCode resultCode;

/// those properties just in case you want it
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, copy, nullable) NSDictionary *extraData;

@end

@implementation BDAccountSealResult

- (instancetype)init {
    self = [super init];
    if (self) {
        self.resultCode = BDAccountSealResultCodeFail;
    }
    
    return self;
}

+ (instancetype)unsupportResult {
    BDAccountSealResult *result = [super unsupportResult];
    result.resultCode = BDAccountSealResultNotSupport;
    return result;
}

+ (instancetype)conflictResult {
    BDAccountSealResult *result = [super conflictResult];
    result.resultCode = BDAccountSealResultConflict;
    
    return result;
}

@end
