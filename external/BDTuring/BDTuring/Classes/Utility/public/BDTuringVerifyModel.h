//
//  BDTuringVerifyModel.h
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyResult;

/*
 model to request a verify result
 */
@interface BDTuringVerifyModel : NSObject

/**
 you should set the property before call -[BDTuring popVerifyViewWithModel]
 */
@property (nonatomic, assign) BDTuringRegionType regionType;

/*
 will only callback once
 */
@property (atomic, copy, nullable) BDTuringVerifyResultCallback callback;

@property (nonatomic, assign) BOOL hideLoading;

/// will just call the callback on mainqueue and then set the callback to nil
- (void)handleResult:(BDTuringVerifyResult *)result;


@end

NS_ASSUME_NONNULL_END
