//
//  BDPModel+H5Gadget.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/25.
//

#import "BDPModel+H5Gadget.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPUtils.h"
#import <objc/runtime.h>
#import "BDPStorageModuleProtocol.h"
#import "BDPModel+Private.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import "BDPSchemaCodec.h"

/// meta中存储H5小程序相关信息的字段
static NSString *const kBDPModelWebAppKey = @"web_app";
static NSString *const kBDPModelWebAppURLKey = @"url";
static NSString *const kBDPModelWebAppVersionCodeKey = @"version_code";
static NSString *const kBDPModelWebAppMD5Key = @"md5";
/// H5小程序代码包目录名称后缀
static NSString *const kBDPModelWebAppPathSuffix = @"h5app__";

/// 存放BDPModel中的H5小程序相关信息
@interface _BDPWebAppModel : NSObject

@property (nonatomic, strong) NSString *URL;
@property (nonatomic, assign) long long versionCode;
@property (nonatomic, strong) NSString *md5;

/// 从BDPModel的extraDict中存放H5小程序相关信息的key中实例化
+ (_BDPWebAppModel *)webAppModelFromExtraDict:(NSDictionary *)extraDict;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

@implementation _BDPWebAppModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        _URL = [dict bdp_stringValueForKey:kBDPModelWebAppURLKey];
        _versionCode = [dict bdp_longlongValueForKey:kBDPModelWebAppVersionCodeKey];
        _md5 = [dict bdp_stringValueForKey:kBDPModelWebAppMD5Key];
    }
    return self;
}

+ (_BDPWebAppModel *)webAppModelFromExtraDict:(NSDictionary *)extraDict {
    _BDPWebAppModel *webAppModel;
    NSDictionary *dict = [extraDict bdp_dictionaryValueForKey:kBDPModelWebAppKey];
    if (!BDPIsEmptyDictionary(dict)) {
        webAppModel = [[_BDPWebAppModel alloc] initWithDict:dict];
    } else {
        webAppModel = [[_BDPWebAppModel alloc] initWithDict:nil];
    }
    return webAppModel;
}

@end

@interface BDPModel ()

@property (nonatomic, strong, readonly) _BDPWebAppModel *webAppModel;

@end

@implementation BDPModel (H5Gadget)

- (_BDPWebAppModel *)webAppModel
{
    _BDPWebAppModel *webAppModel = objc_getAssociatedObject(self, @selector(webAppModel));
    if (webAppModel) {
        return webAppModel;
    }
    webAppModel = [_BDPWebAppModel webAppModelFromExtraDict:self.extraDict];
    objc_setAssociatedObject(self, @selector(webAppModel), webAppModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return webAppModel;
}

- (NSString *)h5WebURL
{
    return self.webAppModel.URL;
}

- (void)setH5WebURL:(NSString *)h5WebURL
{
    if (!BDPIsEmptyString(h5WebURL)) {
        self.webAppModel.URL = h5WebURL;
    }
}

- (int64_t)h5WebVersionCode
{
    return self.webAppModel.versionCode;
}

- (void)setH5WebVersionCode:(int64_t)h5WebVersionCode
{
    self.webAppModel.versionCode = h5WebVersionCode;
}

- (NSString *)h5md5
{
    return self.webAppModel.md5;
}

- (void)setH5md5:(NSString *)h5md5
{
    if (!BDPIsEmptyString(h5md5)) {
        self.webAppModel.md5 = h5md5;
    }
}

- (BOOL)isH5NewerThanAppModel:(BDPModel *)model {
    if (![model.uniqueID.appID isEqualToString:self.uniqueID.appID]) {
        return NO;
    }
    if (![model.uniqueID.identifier isEqualToString:self.uniqueID.identifier]) {
        return NO;
    }
    return model.h5WebVersionCode != self.h5WebVersionCode && ![model.h5md5 isEqualToString:self.h5md5];
}
/// 判断代码包文件路径是否属于H5小程序
+ (BOOL)isH5FolderName:(NSString *)path {
    return [path hasSuffix:kBDPModelWebAppPathSuffix];
}

@end
