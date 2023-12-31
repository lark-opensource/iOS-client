//
//  BDPShareManager.h
//  Timor
//
//  Created by MacPu on 2018/12/29.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPCommon.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPFoundation/BDPShareContext.h>
#import <OPFoundation/BDPSharePluginDelegate.h>
#import "BDPSharePluginModel.h"

typedef NS_ENUM(NSInteger, BDPShareEntryType) {
    BDPShareEntryTypeUnknown = 0, // 未知渠道
    BDPShareEntryTypeToolBar,     // 工具栏渠道 - 右上角"..."
    BDPShareEntryTypeInner,       // 小程序/小游戏内部调用
    BDPShareEntryTypeAnchor       // 锚点分享按钮调用
};

typedef NS_ENUM(NSInteger, BDPShareResultType) {
    BDPShareResultTypeSuccess = 0,
    BDPShareResultTypeFail,
    BDPShareResultTypeCancel
};

typedef void (^BDPGetShareInfoCallback)(BDPSharePluginModel *, NSError *);
typedef void (^BDPGetDefaultShareInfoCallback)(BDPSharePluginModel *, NSError *);

@interface BDPShareManager : NSObject

@property (nonatomic, weak) BDPJSBridgeEngine engine;
@property (nonatomic, strong) NSDictionary *shareChannelParams;

+ (instancetype)sharedManager;

/**
 设置分享调用来源
 
 @param shareEntry 调用来源(BDPShareEntryType)
 */
- (void)setShareEntry:(BDPShareEntryType)shareEntry;

- (void)onShareBegin:(BDPShareContext *)context;
- (void)onShareDone:(BDPShareResultType)result errMsg:(NSString *)errMsg;

@end

