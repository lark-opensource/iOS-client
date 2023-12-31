//
//  BDUGShareAdapterSetting.h
//  Pods
//
//  Created by 张 延晋 on 3/7/15.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGShareBlockProtocol.h"
#import "BDUGShareCommonInfoProtocol.h"
#import "BDUGShareAbilityProtocol.h"
#import "BDUGShareDialogDirectorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareAdapterSetting : NSObject

@property (nonatomic, strong, nullable) id<BDUGShareCommonInfoProtocol> commonInfoDelegate;
@property (nonatomic, strong, nullable) id<BDUGShareBlockProtocol> shareBlockDelegate;
@property (nonatomic, strong, nullable) Class <BDUGShareAbilityProtocol> shareAbilityDelegate;
@property (nonatomic, strong, nullable) Class <BDUGShareDialogDirectorProtocol> shareDialogDelegate;

+ (instancetype)sharedService;

- (BOOL)isPadDevice;

- (UIViewController * _Nullable)topmostViewController;

- (void)activityWillSharedWith:(id<BDUGActivityProtocol> _Nullable)activity;
- (void)activityHasSharedWith:(id<BDUGActivityProtocol> _Nullable)activity error:(NSError * _Nullable)error desc:(NSString *  _Nullable)desc;

- (void)setPanelClassName:(NSString *)panelClassName;
- (NSString *)getPanelClassName;

- (BOOL)shouldBlockShareWithActivity:(id<BDUGActivityProtocol> _Nullable)activity;
- (void)didBlockShareWithActivity:(id<BDUGActivityProtocol> _Nullable)activity continueBlock:(void(^)(void))block;

- (void)shareAbilityShowLoading;
- (void)shareAbilityHideLoading;

@end

NS_ASSUME_NONNULL_END
