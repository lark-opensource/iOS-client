//
//  BDTuringIdentityModel.m
//  BDTuring
//
//  Created by bob on 2020/6/30.
//

#import "BDTuringIdentityModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringIdentityResult.h"

@implementation BDTuringIdentityModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mode = 1;
        self.handlerName = NSStringFromClass([self class]);
    }
    
    return self;
}

- (void)handleResult:(BDTuringVerifyResult *)result {
    if (![result isKindOfClass:[BDTuringIdentityResult class]]) {
        result = [BDTuringIdentityResult unsupportResult];
    }
    
    [super handleResult:result];
}

@end
