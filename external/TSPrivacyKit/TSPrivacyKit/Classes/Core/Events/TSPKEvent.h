//
//  TSPKEvent.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/15.
//

#import <Foundation/Foundation.h>
#import "TSPKEventData.h"
#import "TSPKBaseEvent.h"

@interface TSPKEvent : TSPKBaseEvent

@property (nonatomic) TSPKEventType eventType;
@property (nonatomic, strong, nullable) TSPKEventData *eventData;
@property (nonatomic, copy, nullable) NSDictionary *params;

// ignore detect info
@property (nonatomic, copy, nonnull) NSArray <NSString *> *ignoreSymbolContexts;
@property (nonatomic, copy, nonnull) NSString *methodType;
@property (nonatomic, assign) NSInteger ruleId;
@property (nonatomic, assign) BOOL isIgnore;

- (nullable NSString *)apiType;

@end
