//
//  HMDRecordStore.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/12.
//

#import <Foundation/Foundation.h>

@protocol HMDStoreIMP;
@class HMDStoreMemoryDB;

@interface HMDRecordStore : NSObject

@property (nonatomic, strong, readonly) id<HMDStoreIMP> _Nonnull database;
@property (nonatomic, strong, readonly) HMDStoreMemoryDB *_Nonnull memoryDB;

+ (instancetype _Nonnull)shared;
//数据库文件大小，单位byte
- (unsigned long long)dbFileSize;
//db完全销毁重建
- (BOOL)devastateDatabase;

- (void)saveStoreErrorCode:(NSInteger)errorCode;

@end
