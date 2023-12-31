//
//  BDDYCModule.h
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import <Foundation/Foundation.h>
#import "BDQuaterbackConfigProtocol.h"



#if BDAweme
__attribute__((objc_runtime_name("AWECFDormant")))
#elif BDNews
__attribute__((objc_runtime_name("TTDSolvent")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDUnscathed")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDImplicit")))
#endif
@interface BDDYCModuleConfig : NSObject<BDQuaterbackConfigProtocol>
@property (nonatomic, copy) NSArray *channelList;
@property (nonatomic, copy) NSArray *appVersionList;
@property (nonatomic, copy) NSArray *lazyLoadDlibList;
@property (nonatomic, copy) NSDictionary *exportSymbols;
@property (nonatomic, copy) NSDictionary *osVersionRange;
@property (nonatomic, copy) NSString *loadEnable;
@property (nonatomic, assign) BOOL racEnable;
@property (nonatomic, assign) BOOL encrypted;
@property (nonatomic, assign) int hookType;
@property (nonatomic, assign) BOOL enableCallFuncLog;
@property (nonatomic, assign) BOOL enableLoadIntime;
/**
 是否输出 Module (load + hook) 日志
 */
@property (nonatomic, assign) BOOL enableModInitLog;

/**
 是否在控制台显示 NSLog 日志
 */
@property (nonatomic, assign) BOOL enablePrintLog;

/**
 是否在控制台显示 Instruction 执行日志
 */
@property (nonatomic, assign) BOOL enableInstExecLog;

/**
 是否在控制台显示 Instruction 执行调用堆栈日志
 */
@property (nonatomic, assign) BOOL enableInstCallFrameLog;

@property (nonatomic, assign) BOOL serializeNativeSymbolLookup;

@property (nonatomic, assign) NSInteger bindSymbolMaxConcurrentOperationCount;
@end

NS_ASSUME_NONNULL_BEGIN

//#if BDAweme
//__attribute__((objc_runtime_name("AWECFAlloy")))
//#elif BDNews
//__attribute__((objc_runtime_name("TTDImmutable")))
//#elif BDHotSoon
//__attribute__((objc_runtime_name("HTSDGallant")))
//#elif BDDefault
//__attribute__((objc_runtime_name("BDDMischievous")))
//#endif
@interface BDBDModule : NSObject
@property (nonatomic, strong, readonly) NSError *loadError;
@property (nonatomic, assign, readonly, getter=isLoaded) BOOL loaded;
@property (nonatomic, assign, readonly, getter=isRemoved) BOOL removed;
@property (nonatomic,   copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSArray *files;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, assign, readonly, getter=isMarkAsEncrypted) BOOL markAsEncrypted;

@property (nonatomic, strong, readonly) BDDYCModuleConfig *config;
@end


NS_ASSUME_NONNULL_END
