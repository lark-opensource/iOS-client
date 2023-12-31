//
//  BytedCertTTJSBridgeHandler.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/18.
//

#import "BytedCertTTJSBridgeHandler.h"
#import "BytedCertManager+Private.h"
#import "BytedCertManager+Piper.h"

#import <BDModel/BDModel.h>


@interface BytedCertTTJSBridgeHandler ()

@property (nonatomic, copy) NSDictionary *baseParams;

@property (nonatomic, weak) UIViewController *fromViewController;

@end


@implementation BytedCertTTJSBridgeHandler

- (instancetype)initWithParams:(NSDictionary *)params {
    self = [super init];
    if (self) {
        _baseParams = params;
    }
    return self;
}

- (void)startWithSuperViewController:(UIViewController *)superVC {
    self.fromViewController = superVC;
    [self start];
}

- (void)start {
    BytedCertParameter *parameter = [BytedCertParameter bd_modelWithJSON:_baseParams options:BDModelMappingOptionsSnakeCaseToCamelCase];
    [[BytedCertManager shareInstance] beginAuthorizationWithParameter:parameter fromViewController:_fromViewController completion:^(NSError *_Nullable error, NSDictionary *_Nullable resut) {
        [self class];
    }];
}

@end
