//
//  BDUGShareDialogDirectorProtocol.h
//  Pods
//
//  Created by 杨阳 on 2020/1/6.
//

#import <Foundation/Foundation.h>

typedef void(^BDUGShareDialogBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGShareDialogDirectorProtocol <NSObject>

@optional

#pragma mark - dialog director

+ (void)shareAbilityNeedShowDialog:(BDUGShareDialogBlock _Nullable)showActionBlock hideAction:(BDUGShareDialogBlock _Nullable)hideActionBlock;

+ (void)shareAbilityDidHideDialog;

@end

NS_ASSUME_NONNULL_END
