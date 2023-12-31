//
//  BDAccountSealer.h
//  BDTuring
//
//  Created by bob on 2020/3/4.
//

#import "BDTuringConfig.h"
#import "BDAccountSealDefine.h"
#import "BDAccountSealModel.h"
#import "BDAccountSealResult.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuring, BDTuringConfig, BDAccountSealModel;

/*! @abstract  UIView + WKWebview
*/
__attribute__((objc_subclassing_restricted))
@interface BDAccountSealer : NSObject

/*! @abstract init it with a turing  or a config
*/
- (instancetype)initWithTuring:(BDTuring *)turing;
- (instancetype)initWithConfig:(BDTuringConfig *)config;

/*! @abstract request with model
 @param model the request model, is a BDAccountSealModel
 
 e.g.
 
 BDTuringVerifyResultCallback callback = ^(BDTuringVerifyResult *response) {
     BDAccountSealResult *result = (BDAccountSealResult *)response;
     BDAccountSealResultCode resultCode = result.resultCode;
     work with result
 } ;
 
 BDAccountSealModel *model = [BDAccountSealModel new];
 model.callback = callback;
 model.navigate = ^(BDAccountSealNavigatePage page, NSString *pageType, UINavigationController * navigationController) {
        BDDebugSealNavigatePage *vc = [BDDebugSealNavigatePage new];
        vc.title = page == BDAccountSealNavigatePagePolicy ? @"yyy" : @"xxx";
        [navigationController pushViewController:vc animated:YES];
 };
 [sealer popVerifyViewWithModel:model]
*/
- (void)popVerifyViewWithModel:(BDAccountSealModel *)model;

/**
 query the staus of seal, you will get result from the callback and BDTuringVerifyResult's resultCode and statusCode
 e.g.
 BDAccountSealModel *model = [BDAccountSealModel new];
 model.regionType = BDTuringRegionTypeCN;/// only cn and boe
 model.callback = ^(BDTuringVerifyResult *response) {
     BDAccountSealResult *result = (BDAccountSealResult *)response;
     if (result.resultCode == BDAccountSealResultCodeAllowedSeal) {
         /// allowed to seal, and now is on main thread
     }
 };
 [sealer queryStatusWithModel:model];
 */
- (void)queryStatusWithModel:(BDAccountSealModel *)model;

@end

NS_ASSUME_NONNULL_END
