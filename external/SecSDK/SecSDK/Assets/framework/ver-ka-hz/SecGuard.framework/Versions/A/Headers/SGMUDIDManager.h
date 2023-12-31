//
//  Header.h
//  Pods
//
//  Created by moqianqian on 2020/4/27.
//


@interface SGMUDIDManager : NSObject

@property (atomic, copy) NSString *sec_udid;
@property (atomic) NSInteger udid_status;

typedef void(^SGMUDIDCompletionBlock)(NSError *error);

typedef NS_ENUM(NSUInteger, status) {
    EMPTY = 0,
    CREATED = 1,
    NORMAL = 2,
    SYNCED = 3,
    DANGEROUS = 4,
    UPDATED = 5
};

+ (instancetype)shareInstance;
- (void) udid_SyncWithComletion: (SGMUDIDCompletionBlock)comletion;
- (void) udid_SyncWithComletionUnderLock: (SGMUDIDCompletionBlock)comletion;
- (NSDictionary *) udid_PostParams;

@end
