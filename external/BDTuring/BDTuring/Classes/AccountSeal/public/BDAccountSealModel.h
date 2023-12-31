//
//  BDAccountSealModel.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyModel.h"
#import "BDAccountSealDefine.h"

NS_ASSUME_NONNULL_BEGIN

/*
 the callback you will get a callback with BDAccountSealResult
 e.g.
 BDTuringVerifyResultCallback callback = ^(BDTuringVerifyResult *response) {
     BDAccountSealResult *result = (BDAccountSealResult *)response;
 /// now you have a BDAccountSealResult
 } ;
 
 BDAccountSealModel *model = [BDAccountSealModel new];
 model.callback
 */
@interface BDAccountSealModel : BDTuringVerifyModel

@property (atomic, copy) BDAccountSealNavigateBlock navigate;

@property (atomic, assign) BDAccountSealThemeMode nativeThemeMode;


/// seal now only support CN & BOE
- (BOOL)validated;

@end

NS_ASSUME_NONNULL_END
