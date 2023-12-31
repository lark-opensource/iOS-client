//
//  BDUGShareSettingsUtil.h
//  Pods
//
//  Created by 杨阳 on 2020/1/8.
//

#import <Foundation/Foundation.h>

typedef void(^BDUGShareSettingsHandler)(BOOL succeed);

typedef NS_ENUM(NSInteger, BDUGSettingsRequestStatus) {
    BDUGSettingsRequestStatusDefault = 0,
    BDUGSettingsRequestStatusRequesting = 1,
    BDUGSettingsRequestStatusSucceed = 2,
    BDUGSettingsRequestStatusFailed = 3,
};

extern NSString *const kBDUGShareSettingsKeyAlbumParse;
extern NSString *const kBDUGShareSettingsKeyQRCodeParse;
extern NSString *const kBDUGShareSettingsKeyHiddenmarkParse;
extern NSString *const kBDUGShareSettingsKeyTokenParse;

@interface BDUGShareSettingsUtil : NSObject

@property (nonatomic, assign) BDUGSettingsRequestStatus requestStatus;

+ (instancetype)sharedInstance;

- (void)settingsRequestFinish:(NSDictionary *)settingsDict;

- (void)settingsWithKey:(NSString *)key
                handler:(BDUGShareSettingsHandler)hander;

@end
