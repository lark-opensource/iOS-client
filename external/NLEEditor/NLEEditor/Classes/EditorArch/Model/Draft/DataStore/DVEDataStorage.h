//
//  DVEDataStorage.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2021/2/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEDraftModelProtocol;

@interface DVEDataStorage : NSObject

+ (instancetype)shareStorage;

- (NSArray <DVEDraftModelProtocol>*)getAllDrafts;

- (void)addOneDarftWithModel:(id<DVEDraftModelProtocol>)draft;

- (void)removeOneDraftModel:(id<DVEDraftModelProtocol>)draft;

- (void)syncFile;

@end

NS_ASSUME_NONNULL_END
