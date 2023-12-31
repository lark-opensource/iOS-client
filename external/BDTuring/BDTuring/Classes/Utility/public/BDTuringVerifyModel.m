//
//  BDTuringVerifyModel.m
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringVerifyModel.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyResult+Result.h"
#import "BDTuringVerifyState.h"

@interface BDTuringVerifyModel ()

@property (nonatomic, copy) NSString *appID; /// for dispatch
@property (nonatomic, copy) NSString *plugin;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, assign) NSInteger showToast;
@property (nonatomic, assign) BDTuringVerifyType verifyType;
@property (nonatomic, copy) NSString *userID;

@property (nonatomic, strong) BDTuringVerifyState *state;
@property (nonatomic, copy) NSString *handlerName;
@property (nonatomic, assign) BOOL supportLandscape;

@end

@implementation BDTuringVerifyModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.supportLandscape = NO;
        self.showToast = 0;
        self.handlerName = NSStringFromClass([BDTuringVerifyModel class]);
        self.hideLoading = NO;
    }
    
    return self;
}

- (void)setRegionType:(BDTuringRegionType)regionType {
    _regionType = regionType;
    self.region = turing_regionFromRegionType(regionType);
}

- (void)handleResult:(BDTuringVerifyResult *)result {
    BDTuringVerifyResultCallback callback = self.callback;
    if (callback == nil) {
        return;
    }
    self.callback = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(result);
    });
}

@end
