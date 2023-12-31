//
//  BDTuringConfig.h
//  BDTuring
//
//  Created by bob on 2019/8/27.
//

#import "BDTuringDefine.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/*!
init config
*/
__attribute__((objc_subclassing_restricted))
@interface BDTuringConfig : NSObject

/*! @abstract AppID, required */
@property (nonatomic, copy) NSString *appID;

/*! @abstract channel , required, default @"App Store" */
@property (nonatomic, copy) NSString *channel;

/*! @abstract appname, required  */
@property (nonatomic, copy) NSString *appName;

/*! @abstract appKey, not used */
@property (nonatomic, copy, nullable) NSString *appKey;

/*! @abstract region type, required
*/
@property (nonatomic, assign) BDTuringRegionType regionType;

/*! @abstract language, required
 e.g.
 zh-Hant
 zh-Hans
 or zh
 en
 */
@property (nonatomic, copy) NSString *language;

/// twice verify required,  refer to starling format
@property (nonatomic, copy) NSString *locale;

/// @property (nonatomic, copy, nullable) NSDictionary *theme;
/// please use +[BDTuring setverifyThemeDictionary:]

/*! @abstract delegate required
*/
@property (nonatomic, weak)  id<BDTuringConfigDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
