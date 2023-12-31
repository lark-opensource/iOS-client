//
//  BDTuringIdentityDefine.h
//  BDTuring
//
//  Created by bob on 2020/3/6.
//

#import "BDTuringDefine.h"

#ifndef BDTuringIdentityDefine_h
#define BDTuringIdentityDefine_h

NS_ASSUME_NONNULL_BEGIN

@class BDTuringIdentityResult, BDTuringIdentityModel;

/*! @abstract Identity result  Code
 see  the API Doc
*/
typedef NS_ENUM(NSInteger, BDTuringIdentityCode) {
    BDTuringIdentityCodeNotVerify   = 0,    /// user  cancel it
    BDTuringIdentityCodeFail        = -1,   /// fail
    BDTuringIdentityCodeSuccess     = 1,    /// success
    BDTuringIdentityCodeCancel      = 2,    /// cancel
    BDTuringIdentityCodeManual      = 3,    /// handling
    BDTuringIdentityCodeNotSupport  = 998,  /// not  support
    BDTuringIdentityCodeConflict    = 999,    /// the first api call not ends
};

@protocol BDTuringIdentityHandler <BDTuringVerifyHandler>

/*! @abstract you need implement it
 @param model the request model
 you should use BDTuringIdentityModel actually
 the callback you will get a BDTuringIdentityResult
*/

//- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif

