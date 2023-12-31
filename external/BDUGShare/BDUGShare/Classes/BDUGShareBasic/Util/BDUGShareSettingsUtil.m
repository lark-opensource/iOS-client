//
//  BDUGShareSettingsUtil.m
//  Pods
//
//  Created by 杨阳 on 2020/1/8.
//

#import "BDUGShareSettingsUtil.h"

NSString *const kBDUGShareSettingsLocalKey = @"kBDUGShareSettingsLocalKey";

NSString *const kBDUGShareSettingsKeyAlbumParse = @"album_parse_switch";
NSString *const kBDUGShareSettingsKeyQRCodeParse = @"qrcode_parse_switch";
NSString *const kBDUGShareSettingsKeyHiddenmarkParse = @"hidden_mark_parse_switch";
NSString *const kBDUGShareSettingsKeyTokenParse = @"token_parse_switch";

@interface BDUGShareSettingsUtil ()

@property (nonatomic, strong) NSDictionary *settingsDict;
@property (nonatomic, strong) NSMutableArray <BDUGShareSettingsHandler> *handlersArray;

@end

@implementation BDUGShareSettingsUtil

@synthesize settingsDict = _settingsDict;

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static BDUGShareSettingsUtil * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

#pragma mark - public

- (void)settingsRequestFinish:(NSDictionary *)settingsDict {
    self.settingsDict = settingsDict;
    for (BDUGShareSettingsHandler handler in self.handlersArray) {
        //这里的bool不作为settings返回值。
        !handler ?: handler(YES);
    }
    [self.handlersArray removeAllObjects];
}

- (void)settingsWithKey:(NSString *)key
                handler:(BDUGShareSettingsHandler)hander
{
    if (!key) {
        !hander ?: hander(NO);
        return;
    }
    switch (self.requestStatus) {
        case BDUGSettingsRequestStatusDefault:
        case BDUGSettingsRequestStatusRequesting: {
            //接口没请求，或者正在请求中，注册回调。
            __weak typeof(self) weakSelf = self;
            [self completionHandlerRegister:^(BOOL succeed) {
                BOOL setting = [weakSelf settingForKey:key];
                !hander ?: hander(setting);
                BDUGLoggerInfo(([NSString stringWithFormat:@"settings - %@, %@", key, [NSNumber numberWithBool:setting]]));
            }];
        }
            break;
        case BDUGSettingsRequestStatusSucceed:
        case BDUGSettingsRequestStatusFailed: {
            //成功之后取当次的settings，失败之后取上次请求的settings值。
            BOOL setting = [self settingForKey:key];
            !hander ?: hander(setting);
            BDUGLoggerInfo(([NSString stringWithFormat:@"settings - %@, %@", key, [NSNumber numberWithBool:setting]]));
        }
            break;
        default:
            break;
    }
}

#pragma mark -

- (BOOL)settingForKey:(NSString *)key
{
    NSNumber *number = [self.settingsDict objectForKey:key];
    if (!number || [number boolValue]) {
        //1、接口没下发
        //2、接口下发为1， 都表明settings开关状态为yes。
        return YES;
    } else {
        return NO;
    }
}

- (void)completionHandlerRegister:(BDUGShareSettingsHandler)handler
{
    [self.handlersArray addObject:handler];
}

#pragma mark - set

- (void)setSettingsDict:(NSDictionary *)settingsDict
{
    _settingsDict = settingsDict;
    [[NSUserDefaults standardUserDefaults] setObject:_settingsDict forKey:kBDUGShareSettingsLocalKey];
}

- (void)setRequestStatus:(BDUGSettingsRequestStatus)requestStatus {
    _requestStatus = requestStatus;
    if (requestStatus == BDUGSettingsRequestStatusSucceed ||
        requestStatus == BDUGSettingsRequestStatusFailed) {
        //请求成功和失败，回调settings结果。
        for (BDUGShareSettingsHandler handler in self.handlersArray) {
            //这里的bool不作为settings返回值。
            !handler ?: handler(YES);
        }
        [self.handlersArray removeAllObjects];
    }
}

#pragma mark - get

- (NSDictionary *)settingsDict
{
    _settingsDict = [[NSUserDefaults standardUserDefaults] objectForKey:kBDUGShareSettingsLocalKey];
    return _settingsDict;
}

- (NSMutableArray *)handlersArray
{
    if (!_handlersArray) {
        _handlersArray = [[NSMutableArray alloc] init];
    }
    return _handlersArray;
}

@end
