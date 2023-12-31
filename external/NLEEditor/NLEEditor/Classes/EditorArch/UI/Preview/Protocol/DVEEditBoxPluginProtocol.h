//
//  DVEEditBoxPluginProtocol.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/5.
//

#import <Foundation/Foundation.h>
#import "DVEPreviewPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEVCContext;

@protocol DVEEditBoxPluginProtocol <DVEPreviewPluginProtocol>

@property (nonatomic, weak) DVEVCContext *vcContext;

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext;

- (void)refreshEditBoxWithSlotID:(nullable NSString *)slotId;

- (void)refreshWithSlotIDs:(NSArray<NSString *> *)slotIds;

- (void)replaceItemsWithSlotIDs:(NSArray<NSString *> *)slotIds;

- (void)activeEditBox:(nullable NSString *)slotId;

- (void)addEditBoxWithSlotID:(NSString *)slotId;

- (void)removeEditBoxWithSlotID:(NSString *)slotId;

@optional

- (NSArray<NSValue *> *)editItemBoxRectValues;

@end

NS_ASSUME_NONNULL_END
