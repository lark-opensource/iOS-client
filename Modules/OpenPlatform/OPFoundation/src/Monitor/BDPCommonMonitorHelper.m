//
//  BDPCommonMonitorHelper.m
//  Timor
//
//  Created by houjihu on 2020/6/4.
//

#import <Foundation/Foundation.h>
#import "BDPCommonMonitorHelper.h"
#import "BDPJSBridgeProtocol.h"
#import "BDPTracingManager.h"
#import "BDPUniqueID.h"

BDPMonitorEvent *CommonMonitorWithNameIdentifierType(NSString *eventName, BDPUniqueID *uniqueID) {
    return (BDPMonitorEvent *)CommonMonitorWithName(eventName)
    .bdpTracing([BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID])
    .kv(kEventKey_identifier, uniqueID.identifier)
    .kv(kEventKey_app_type, OPAppTypeToString(uniqueID.appType));
}

BDPMonitorEvent *CommonMonitorWithCodeIdentifierType(OPMonitorCode *monitorCode, BDPUniqueID *uniqueID) {
    return (BDPMonitorEvent *)CommonMonitorWithCode(monitorCode)
    .bdpTracing([BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID])
    .kv(kEventKey_identifier, uniqueID.identifier)
    .kv(kEventKey_app_type, OPAppTypeToString(uniqueID.appType));
}

BDPMonitorEvent *CommonMonitorWithName(NSString *eventName) {
    return BDPMonitorWithName(eventName, nil);
}

BDPMonitorEvent *CommonMonitorWithCode(OPMonitorCode *monitorCode) {
    return BDPMonitorWithCode(monitorCode, nil);
}

BDPMonitorEvent * _Nonnull BDPMonitorWithNameAndEngine(NSString * _Nonnull eventName, id<BDPEngineProtocol> _Nullable engine) {
    if ([engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        id<BDPJSBridgeEngineProtocol> jsBridgeEngine = (id<BDPJSBridgeEngineProtocol>)engine;
        return BDPMonitorWithName(eventName, jsBridgeEngine.uniqueID);
    }
    BDPTracing *tracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:engine.uniqueID];
    return (BDPMonitorEvent *)[[BDPMonitorEvent alloc] initWithService:nil name:eventName monitorCode:nil].setUniqueID(engine.uniqueID).bdpTracing(tracing);
}
