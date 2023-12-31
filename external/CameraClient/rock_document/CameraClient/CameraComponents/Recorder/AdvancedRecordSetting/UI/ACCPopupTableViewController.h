//
//  ACCPopupTableViewController.h
//  Indexer
//
//  Created by Shichen Peng on 2021/10/27.
//

#import <UIKit/UIKit.h>

// CameraClient
#import <CameraClient/ACCPopupViewControllerProtocol.h>
#import <CameraClient/ACCAdvancedRecordSettingDataManager.h>

// CreativeKit
#import <CreativeKit/ACCPanelViewController.h>

#pragma mark - ACCPopupTableViewController

@interface ACCPopupTableViewController : UIViewController <ACCPopupTableViewControllerProtocol, ACCPanelViewProtocol>

@property (nonatomic, strong, readonly, nonnull) id<ACCPopupTableViewDataManagerProtocol> dataManager;

- (instancetype)initWithDataManager:(id<ACCPopupTableViewDataManagerProtocol>)dataManager;

@end


