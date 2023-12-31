//
//  BDAccountSealModel.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDAccountSealModel.h"
#import "BDAccountSealResult.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringUtility.h"

@implementation BDAccountSealModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.handlerName = NSStringFromClass(self.class);
        self.regionType = BDTuringRegionTypeCN;
        self.region = kBDTuringRegionCN;
        self.nativeThemeMode = BDAccountSealThemeModeLight;
    }
    
    return self;
}

- (void)handleResult:(BDTuringVerifyResult *)result {
    if (![result isKindOfClass:[BDAccountSealResult class]]) {
        result = [BDAccountSealResult unsupportResult];
    }
    
    [super handleResult:result];
}

- (BOOL)validated {
    BDTuringRegionType regionType = self.regionType;
    return regionType == BDTuringRegionTypeCN;
}

- (void)setRegionType:(BDTuringRegionType)regionType {
    [super setRegionType:regionType];
    self.region = turing_regionFromRegionType(regionType);
}

@end
