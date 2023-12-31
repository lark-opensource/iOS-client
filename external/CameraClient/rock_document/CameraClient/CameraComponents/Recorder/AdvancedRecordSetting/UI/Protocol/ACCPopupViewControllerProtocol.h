//
//  ACCPopupViewControllerProtocol.h
//  Aweme
//
//  Created by Shichen Peng on 2021/10/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// CameraClient
#import <CameraClient/ACCAdvancedRecordSettingItem.h>

// CreativeKit
#import <CreativeKit/ACCPanelViewProtocol.h>
#import <CreativeKit/ACCPanelViewController.h>

#ifndef ACCPopupViewControllerProtocol_h
#define ACCPopupViewControllerProtocol_h

@protocol ACCPopupTableViewControllerProtocol, ACCPopupTableViewControllerDelegateProtocol, ACCPopupTableViewCellProtocol, ACCPopupTableViewDataItemProtocol;

@protocol ACCPopupTableViewControllerProtocol <NSObject>

@property (nonatomic, weak, nullable) id<ACCPopupTableViewControllerDelegateProtocol> delegate;

- (CGFloat)contentHeight;

@end

@protocol ACCPopupTableViewControllerDelegateProtocol <NSObject>

- (void)showPanel;
- (void)dismissPanel;

@end

@protocol ACCPopupViewControllerProtocol <NSObject>

@end

@protocol ACCPopupTableViewCellDelegateProtocol <NSObject>
 
@end

@protocol ACCPopupTableViewCellProtocol <NSObject>

- (void)updateWithItem:(id<ACCPopupTableViewDataItemProtocol>)item;
+ (CGFloat)cellHeight;

@optional
- (void)onCellClicked;

@optional

@property (nonatomic, weak, nullable) id<ACCPopupTableViewCellDelegateProtocol> delegate;

@end

#endif /* ACCPopupViewControllerProtocol_h */
