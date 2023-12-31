//
//  ACCAdvancedRecordSettingDataManager.h
//  Indexer
//
//  Created by Shichen Peng on 2021/10/28.
//

#import <Foundation/Foundation.h>

//CameraClient
#import <CameraClient/ACCPopupViewControllerProtocol.h>

@protocol ACCPopupTableViewDataManagerProtocol <NSObject>

@property (nonatomic, strong, nonnull) NSMutableArray<id<ACCPopupTableViewDataItemProtocol>> *items;
@property (nonatomic, copy, nonnull) NSArray<id<ACCPopupTableViewDataItemProtocol>> *selectedItems;

- (void)addItem:(id<ACCPopupTableViewDataItemProtocol> _Nonnull)item;
- (id<ACCPopupTableViewDataItemProtocol>)getItemAtIndex:(NSIndexPath *)indexPath;
- (NSInteger)countOfSelectedItems;
- (void)updateSelectedItemsIfNeed:(BOOL)needSync;

@end

@interface ACCAdvancedRecordSettingDataManager : NSObject <ACCPopupTableViewDataManagerProtocol>

@end
