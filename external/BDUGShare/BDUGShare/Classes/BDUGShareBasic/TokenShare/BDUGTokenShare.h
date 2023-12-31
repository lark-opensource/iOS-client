//
//  BDUGTokenShare.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGShareDataModel.h"

typedef NS_ENUM(NSInteger, BDUGTokenShareStatusCode) {
    BDUGTokenShareStatusCodeSuccess = 0,//去粘贴
    BDUGTokenShareStatusCodeUserCancel,//用户不去粘贴
    BDUGTokenShareStatusCodeGetTokenFailed,//获取口令失败
    BDUGTokenShareStatusCodePlatformOpenFailed,//打开第三方app失败
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDUGTokenShareCompletionHandler)(BDUGTokenShareStatusCode statusCode, NSString * _Nullable desc);

@interface BDUGTokenShareInfo: NSObject

@property (nonatomic, copy, nullable) NSString *groupID;
@property (nonatomic, copy, nullable) NSString *shareUrl;

@property (nonatomic, copy, nullable) NSString *tokenDesc;
@property (nonatomic, copy, nullable) NSString *tokenTitle;
@property (nonatomic, copy, nullable) NSString *tokenTips;

@property (nonatomic, copy, nullable) NSString *platformString;
@property (nonatomic, copy, nullable) NSString *channelStringForEvent;

@property (nonatomic, copy, nullable) NSString *panelId;
@property (nonatomic, copy, nullable) NSString *panelType;

@property (nonatomic, copy, nullable) BDUGTokenShareCompletionHandler completeBlock;
@property (nonatomic, copy, nullable) BDUGActivityTokenDialogDidShow dialogDidShowBlock;
@property (nonatomic, copy, nullable) BDUGShareOpenThirPlatform openThirdPlatformBlock;

@property (nonatomic, strong, nullable) NSDictionary *clientExtraData;

@end

@interface BDUGTokenShare : NSObject
+ (void)shareTokenWithInfo:(BDUGTokenShareInfo *)info;

+ (BOOL)isAvailable;
@end

NS_ASSUME_NONNULL_END
