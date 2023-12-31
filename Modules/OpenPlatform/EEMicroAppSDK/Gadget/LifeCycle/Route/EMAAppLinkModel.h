//
//  EMAAppLinkModel.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kAppLink_appId;
extern NSString * const kAppLink_path;
extern NSString * const kAppLink_path_android;
extern NSString * const kAppLink_path_ios;
extern NSString * const kAppLink_path_ipa;
extern NSString * const kAppLink_path_pc;
extern NSString * const kAppLink_mode;
extern NSString * const kAppLink_min_lk_ver;
extern NSString * const kAppLink_min_lk_ver_android;
extern NSString * const kAppLink_min_lk_ver_ios;
extern NSString * const kAppLink_min_lk_ver_ipad;
extern NSString * const kAppLink_min_lk_ver_pc;
extern NSString * const kAppLink_op_tracking;

typedef NS_ENUM(NSUInteger, EMAAppLinkType) {
    EMAAppLinkTypeOpen = 0,
};

@interface EMAAppLinkModel : NSObject

@property (nonatomic, assign, readonly) EMAAppLinkType type;

- (instancetype)initWithType:(EMAAppLinkType)type;

- (EMAAppLinkModel * (^)(NSString *key, NSString *value))addQuery;

- (NSURL *)generateURL;

@end

NS_ASSUME_NONNULL_END

