//
//  BDTuringIdentity.h
//  BDTuring
//
//  Created by bob on 2020/3/6.
//

#import "BDTuringIdentityDefine.h"
#import "BDTuringIdentityModel.h"
#import "BDTuringIdentityResult.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDTuringIdentityModel;

/**
 just a Identity service, you need implement  the handler by calling `byted_cert`
 */
__attribute__((objc_subclassing_restricted))
@interface BDTuringIdentity : NSObject

/*! @abstract must implement  the handler
@discussion the handler should call `byted_cert`
*/
@property (nonatomic, weak) id<BDTuringIdentityHandler> handler;

/*! @abstract init with appid
@discussion callback on main queue, recommend you init it ahead
*/
+ (instancetype)identityWithAppID:(NSString *)appID;

/*! @abstract start a verify action
 @discussion onceCallback only once
 @discussion you might need to handle  the naviagtionbar if you call this api manully
*/
- (void)popVerifyViewWithModel:(BDTuringIdentityModel *)model;

@end

NS_ASSUME_NONNULL_END
