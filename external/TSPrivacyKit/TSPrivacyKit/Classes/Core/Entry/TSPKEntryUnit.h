//
//  TSPKEntryUnit.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import <Foundation/Foundation.h>

#import "TSPKAPIModel.h"
#import "TSPKStore.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKHandleResult.h"

typedef void (^TSPKEntryUnitInitAction)(void);

@interface TSPKEntryUnitModel : NSObject

@property (nonatomic, copy, nullable) NSString *entryIdentifier;
@property (nonatomic, copy, nullable) TSPKEntryUnitInitAction initAction;
@property (nonatomic) TSPKStoreType storeType;

@property (nonatomic, copy, nullable) NSString *pipelineType;
@property (nonatomic, copy, nullable) NSString *dataType;
@property (nonatomic, copy, nullable) NSString *clazzName;
@property (nonatomic, copy, nullable) NSArray<NSString *> *apis;
@property (nonatomic, copy, nullable) NSArray<NSString *> *cApis;

@end

@interface TSPKEntryUnit : NSObject

@property (nonatomic, copy, nullable) NSString *entryType;

- (instancetype _Nullable)initWithModel:(TSPKEntryUnitModel *_Nullable)model;

- (void)setEnable:(BOOL)enable;

- (TSPKHandleResult *_Nullable)handleAccessEntry:(TSPKAPIModel *_Nullable)model;

@end


