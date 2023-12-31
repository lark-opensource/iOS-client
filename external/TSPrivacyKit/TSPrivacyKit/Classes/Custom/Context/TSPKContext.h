//
//  TSPKContext.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import <Foundation/Foundation.h>

#import "TSPrivacyKitConstants.h"


@interface TSPKContext : NSObject

- (NSSet<NSString *> *_Nullable)contextSymbolsForApiType:(NSString *_Nullable)apiType;

- (void)setContextBlock:(TSPKFetchDetectContextBlock _Nullable)contextBlock forApiType:(NSString *_Nullable)apiType;

@end

