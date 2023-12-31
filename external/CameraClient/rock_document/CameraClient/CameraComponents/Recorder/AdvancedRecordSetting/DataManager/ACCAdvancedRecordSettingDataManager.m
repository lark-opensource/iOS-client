//
//  ACCAdvancedRecordSettingDataManager.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/28.
//

#import "ACCAdvancedRecordSettingDataManager.h"
#import "ACCAdvancedRecordSettingItem.h"

// ByteDanceKit
#import <ByteDanceKit/NSArray+BTDAdditions.h>
// CreativeKit
#import <CreativeKit/ACCCacheProtocol.h>
// CameraClient
#import <CameraClient/ACCAdvancedRecordSettingConfigManager.h>

@implementation ACCAdvancedRecordSettingDataManager

@synthesize items = _items, selectedItems = _selectedItems;

- (instancetype)init
{
    if (self = [super init]) {
        _items = [NSMutableArray array];
        [self updateSelectedItemsIfNeed:NO];
    }
    return self;
}

- (void)addItem:(id<ACCPopupTableViewDataItemProtocol> _Nonnull)item
{
    [self.items btd_addObject:item];
}

- (id<ACCPopupTableViewDataItemProtocol>)getItemAtIndex:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.selectedItems count]) {
        return [self.selectedItems btd_objectAtIndex:indexPath.row];
    } else {
        return nil;
    }
}

- (NSInteger)countOfSelectedItems
{
    return [self.selectedItems count];
}

- (void)updateSelectedItemsIfNeed:(BOOL)needSync
{
    NSMutableArray *targetItems = [NSMutableArray array];
    [self.items enumerateObjectsUsingBlock:^(id<ACCPopupTableViewDataItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<ACCPopupTableViewDataItemProtocol> item = (id<ACCPopupTableViewDataItemProtocol>)obj;
        if (item.needShow()) {
            // 这里需要检查一下配置是否同步，因为从编辑页->裁剪->重拍->修改面板设置->回到拍摄页时可能会失去同步。
            // Need to synchronize settings when returning from the reshoot of edit page.
            if ([self isSwitchOutOfSync:item.switchState withType:item.itemType] && [ACCAdvancedRecordSettingConfigManager isLocalChanged:item.itemType]) {
                item.switchState = [ACCCache() integerForKey:[ACCAdvancedRecordSettingConfigManager typeToKey:item.itemType]];
            }
            [targetItems btd_addObject:item];
        }
        [self syncSetting:item needSync:needSync];
    }];
    _selectedItems = [targetItems copy];
}

- (void)syncSetting:(id<ACCPopupTableViewDataItemProtocol>)item needSync:(BOOL)needSync
{
    if (!needSync) {
        return;
    }
    if (item.needShow()) {
        if (item.segmentActionBlock) {
            item.segmentActionBlock(item.index, YES);
        }
        if (item.switchActionBlock) {
            item.switchActionBlock(item.switchState, YES);
        }
    } else {
        if (item.switchActionBlock) {
            item.switchActionBlock(NO, YES);
        }
    }
}

- (BOOL)isSwitchOutOfSync:(BOOL)state withType:(ACCAdvancedRecordSettingType)type
{
    return [ACCCache() integerForKey:[ACCAdvancedRecordSettingConfigManager typeToKey:type]] != state && [ACCAdvancedRecordSettingConfigManager isSwitchType:type];
}

@end
