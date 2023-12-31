//
//  BDUGTokenShare.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGImageShareDialogManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDUGImageShareCompletionHandler)(BDUGImageShareStatusCode statusCode, NSString * _Nullable desc);

@interface BDUGImageShareInfo: NSObject

@property (nonatomic, copy, nullable) NSString *groupID;
@property (nonatomic, copy, nullable) NSString *panelID;
@property (nonatomic, copy, nullable) NSString *panelType;
@property (nonatomic, copy, nullable) NSString *platformString;
@property (nonatomic, copy, nullable) NSString *channelStringForEvent;

@property (nonatomic, copy, nullable) NSString *imageUrl;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, assign) BOOL writeToken;

@property (nonatomic, copy, nullable) NSString *imageTokenDesc;
@property (nonatomic, copy, nullable) NSString *imageTokenTitle;
@property (nonatomic, copy, nullable) NSString *imageTokenTips;

@property (nonatomic, copy, nullable) BDUGShareOpenThirPlatform openThirdPlatformBlock;
@property (nonatomic, copy, nullable) BDUGImageShareCompletionHandler completeBlock;
@property (nonatomic, copy, nullable) BDUGActivityTokenDialogDidShow dialogDidShowBlock;

@property (nonatomic, strong, nullable) NSDictionary *clientExtraData;

@end

@interface BDUGImageShare : NSObject

+ (void)shareImageWithInfo:(BDUGImageShareInfo *)info;

+ (BOOL)isAvailable;

@end

NS_ASSUME_NONNULL_END
