//
//  OPEnvTypeHelper.h
//  OPFoundation
//
//  Created by yinyuan on 2021/1/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OPEnvType) {
    OPEnvTypeOnline,
    OPEnvTypeStaging,
    OPEnvTypePreRelease
};

FOUNDATION_EXPORT NSString *OPEnvTypeToString(OPEnvType envType);

@interface OPEnvTypeHelper : NSObject

@property (class, nonatomic, assign) OPEnvType envType;

@end

NS_ASSUME_NONNULL_END
