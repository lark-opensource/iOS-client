//
//  BDXServiceDefines.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BDXServiceType) {
    BDXServiceTypeResourceLoader = 1 << 0,
    BDXServiceTypeContainerView = 1 << 1,
    BDXServiceTypeContainerPage = 1 << 2,
    BDXServiceTypeContainerPopUp = 1 << 3,
    BDXServiceTypeSchema = 1 << 4,
    BDXServiceTypeLynxKit = 1 << 5,
    BDXServiceTypeWebKit = 1 << 6,
    BDXServiceTypeMonitor = 1 << 7,
    BDXServiceTypeRouter = 1 << 8,
    BDXServiceTypeOptimize = 1 << 9,
};

typedef NS_OPTIONS(NSUInteger, BDXServiceScope) {
    BDXServiceScopeCustomized = 1 << 0,
    BDXServiceScopeGlobalDefault = 1 << 1,
};

#define DEFAULT_SERVICE_BIZ_ID @"xdefault"

#define BDXSERVICE_SINGLETON_IMP                   \
    static id _sharedInst = nil;                   \
    +(instancetype)sharedInstance                  \
    {                                              \
        static dispatch_once_t onceToken;          \
        dispatch_once(&onceToken, ^{               \
            if (!_sharedInst) {                    \
                _sharedInst = [[self alloc] init]; \
            }                                      \
        });                                        \
        return _sharedInst;                        \
    }

NS_ASSUME_NONNULL_END
