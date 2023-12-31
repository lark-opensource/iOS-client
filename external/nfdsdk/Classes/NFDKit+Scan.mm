//
//  NFDKit+Scan.m
//  nfdsdk
//
//  Created by lujunhui.2nd on 2023/1/30.
//
#import <Foundation/Foundation.h>
#import "NFDSDK.hpp"
#import "NFDKit+Scan.h"
#import "P_NFDKit+PSDA.h"

@interface NFDKit()
@property(readwrite) NFDKitScanCallback scanCallback;
@end

void scanCB(int instanceID, const char *paramJson, NFDScanErrorCode errorCode) {
    @autoreleasepool {
        NFDKit* instance = [[NFDKit getInstanceMap] objectForKey:[NSNumber numberWithInt:instanceID]];
        if (instance == nullptr) {
            return;
        }
        if (instance.scanCallback != nullptr) {
            instance.scanCallback([NSString stringWithCString:paramJson encoding:NSUTF8StringEncoding], (NFDKitScanErrorCode) errorCode);
        }
    }
};

@implementation NFDKit (Scan)


// MARK: - Scan

///
/// SDK: `void NFDScannerInit(nfd::NFDLoggerCallback loggerCB,nfd::NFDTrackerFuncCallback trackerFuncCB);`
- (void)initScanner {
    NFDScannerInit(self.scannerID, nullptr, nullptr);
}

-(bool)isScannerInit {
    return NFDScannerIsInit(self.scannerID);
}

///
/// SDK: `int NFDScannerConfig(const char *nfdScanJson, int len);`
- (NFDKitReturnValue)configScan:(NSString*)configJson
{
    const char* configJsonCstr = [configJson cStringUsingEncoding:NSUTF8StringEncoding];
    return (NFDKitReturnValue)NFDScannerConfig(self.scannerID,configJsonCstr);
}

///
/// SDK: `int NFDScannerStart(int timeout, NFDScanMode mode, NFDScanCallback callback);`
- (NFDKitReturnValue)startScan:(int)timeout andMode:(NFDKitScanMode)mode andUsage:(NFDKitUsage)usage andCallback:(NFDKitScanCallback)callback 
{
    [self stopScan];
    [self setScanCallback:callback];
#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
    [NFDKit p_setBleScanPSDAToken: self.token];
#endif
    return (NFDKitReturnValue)NFDScannerStart(self.scannerID,
                                              timeout,
                                              static_cast<NFDScanMode>(mode),
                                              scanCB,
                                              static_cast<NFDUsage>(usage));
}

///
/// SDK: `int NFDScannerStop();`
- (NFDKitReturnValue)stopScan
{
    return (NFDKitReturnValue)NFDScannerStop(self.scannerID);
}

///
/// SDK: `void NFDScannerUninit();`
- (void)uninitScan
{
    NFDScannerUninit(self.scannerID);
}

@end
