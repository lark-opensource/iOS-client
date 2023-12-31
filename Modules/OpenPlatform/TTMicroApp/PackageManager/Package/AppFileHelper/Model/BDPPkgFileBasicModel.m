//
//  BDPAppFileBasicModel.m
//  TTHelium
//
//  Created by 傅翔 on 2019/3/5.
//

#import "BDPPkgFileBasicModel.h"

@interface BDPPkgFileBasicModel ()

@property (nonatomic, copy) NSString *pkgIdentifier;
@property (nonatomic, copy) NSString *pkgName;
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSArray<NSURL *> *requestURLs;
@property (nonatomic, assign) int64_t versionCode;
@property (nonatomic, assign) BOOL isDebugMode;

@end

@implementation BDPPkgFileBasicModel

+ (instancetype)basicModelWithUniqueId:(BDPUniqueID *)uniqueId md5:(NSString *)md5 pkgName:(NSString *)pkgName readType:(BDPPkgFileReadType)readType requestURLs:(NSArray<NSURL *> *)requestURLs version:(NSString *)version versionCode:(int64_t)versionCode debugMode:(BOOL)debugMode {
    BDPPkgFileBasicModel *model = [[BDPPkgFileBasicModel alloc] init];
    model.md5 = md5;
    model.pkgName = pkgName;
    model.pkgIdentifier = [self pkgIdentifierWithUniqueID:uniqueId pkgName:pkgName];
    model.readType = readType;
    model.version = version;
    model.requestURLs = requestURLs;
    model.versionCode = versionCode;
    model.isDebugMode = debugMode;
    model.uniqueID = uniqueId;
    return model;
}

+ (NSString *)pkgIdentifierWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    // TODO: 需要验证是否有影响
    return pkgName.length ? [NSString stringWithFormat:@"%@_%@", uniqueID.fullString, pkgName] : uniqueID.fullString;
}

#pragma mark -
- (void)setReadType:(BDPPkgFileReadType)readType {
    if (_readType == BDPPkgFileReadTypePreload && readType != BDPPkgFileReadTypePreload) {
        _isReusePreload = YES;
    }
    _readType = readType;
}

#pragma mark - Computed Property
// TODO: 即将删除
- (NSString *)appId {
    return _uniqueID.appID;
}

// TODO: 即将删除
- (OPAppVersionType)versionType {
    return _uniqueID.versionType;
}

// TODO: 即将删除
- (BDPType)appType {
    return _uniqueID.appType;
}

- (float)downloadPriority {
    switch (_priority) {
        case BDPAppLoadPriorityHighest:
            return NSURLSessionTaskPriorityHigh;
        case BDPAppLoadPriorityHigh:
            return NSURLSessionTaskPriorityDefault;
        case BDPAppLoadPriorityNormal:
        default:
            return NSURLSessionTaskPriorityLow;
    }
}

#pragma MARK -
- (BOOL)isEqual:(BDPPkgFileBasicModel *)object {
    if (self == object) {
        return YES;
    } else if (![object isKindOfClass:[self class]]) {
        return NO;
    } else {
        return [object.pkgIdentifier isEqual:self.pkgIdentifier];
    }
}

- (NSUInteger)hash {
    return _pkgIdentifier.hash;
}

@end
