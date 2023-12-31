//
//  BDPAppLoadURLInfo.h
//  Timor
//
//  Created by 傅翔 on 2019/2/2.
//

#import <Foundation/Foundation.h>

#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BDPAccessFolder) {
    /** 目录非法, 无权限访问 */
    BDPAccessFolderInvalid,
    /** TTPkg目录 */
    BDPAccessFolderTTPKG,
    /** JSSDK目录 */
    BDPAccessFolderJSSDK,
    /** 沙盒目录: user、temp */
    BDPAccessFolderSandBox
};

/**
 记录小游戏/程序 发起的资源请求
 */
@interface BDPAppLoadURLInfo : NSObject

@property (nonatomic, copy) NSURL *requestURL;

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *pkgName;

@property (nonatomic, assign) BDPAccessFolder folder;
/** 处理过的真实路径(相对/绝对) */
@property (nonatomic, copy) NSString *realPath;

@property (nonatomic, strong) OPAppUniqueID *uniqueID;

+ (NSString * _Nonnull)uniqueKeyForURLRequest:(NSURLRequest *)urlRequest;

+ (OPAppUniqueID * _Nullable)parseUniqueIDFromURLRequest:(NSURLRequest *)urlRequest;

@end

NS_ASSUME_NONNULL_END
