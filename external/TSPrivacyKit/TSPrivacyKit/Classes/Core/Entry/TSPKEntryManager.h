//
//  TSPKEntryManager.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/22.
//

#import <Foundation/Foundation.h>

@class TSPKHandleResult;
@class TSPKEntryUnit;
@class TSPKEntryUnitModel;
@class TSPKAPIModel;

typedef BOOL (^TSPKCustomCanHandleBuilder)(TSPKAPIModel *_Nullable apiModel);

@interface TSPKEntryManager : NSObject

+ (nullable instancetype)sharedManager;

- (void)registerCustomCanHandleBuilder:(nullable TSPKCustomCanHandleBuilder)builder;

- (void)registerEntryType:(NSString *_Nullable)entryType entryModel:(TSPKEntryUnitModel *_Nullable)entryModel;

- (void)setEntryType:(NSString *_Nullable)entryType enable:(BOOL)enable;

- (TSPKHandleResult *_Nullable)didEnterEntry:(NSString *_Nullable)entryType withModel:(TSPKAPIModel *_Nullable)model;

- (BOOL)respondToEntryToken:(NSString *_Nullable)entryToken context:(NSDictionary *_Nullable)context;

- (BOOL)canHandleEventModel:(TSPKAPIModel *_Nullable)model;

@end


