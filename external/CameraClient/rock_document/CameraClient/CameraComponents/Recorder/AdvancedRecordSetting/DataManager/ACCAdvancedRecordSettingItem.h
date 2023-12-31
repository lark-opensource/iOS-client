//
//  ACCAdvancedRecordSettingItem.h
//  Indexer
//
//  Created by Shichen Peng on 2021/10/28.
//

#import <Foundation/Foundation.h>

//CameraClient
#import <CameraClient/ACCPopupViewControllerProtocol.h>

typedef NS_ENUM(NSUInteger, ACCAdvancedRecordSettingType) {
    ACCAdvancedRecordSettingTypeNone = 0,
    ACCAdvancedRecordSettingTypeMaxDuration,
    ACCAdvancedRecordSettingTypeBtnAsShooting,
    ACCAdvancedRecordSettingTypeTapToTakePhoto,
    ACCAdvancedRecordSettingTypeMultiLensZooming,
    ACCAdvancedRecordSettingTypeCameraGrid
};

typedef NS_ENUM(NSUInteger, ACCPopupCellType) {
    ACCPopupCellTypeSwitch = 0,
    ACCPopupCellTypeSegment
};

@protocol ACCPopupTableViewCellProtocol;

@protocol ACCPopupTableViewDataItemProtocol <NSObject>

// UI related
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *content;
@property (nonatomic, strong, nonnull) UIImage *iconImage;
@property (nonatomic, strong, nonnull) Class<ACCPopupTableViewCellProtocol> cellClass;
@property (nonatomic, assign) ACCPopupCellType cellType;

// Control related
@property (nonatomic, assign) BOOL switchState;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) ACCAdvancedRecordSettingType itemType;

@property (nonatomic, assign) BOOL touchEnable;

@property (nonatomic, copy, nonnull) BOOL(^needShow)(void);

// 非用户主动触发
@property (nonatomic, copy, nullable) void(^segmentActionBlock)(NSUInteger index, BOOL needSync);
@property (nonatomic, copy, nullable) void(^switchActionBlock)(BOOL switchState, BOOL needSync);

// 用户主动触发
@property (nonatomic, copy, nullable) void(^segmentActionBlockWrapper)(NSUInteger index);
@property (nonatomic, copy, nullable) void(^switchActionBlockWrapper)(BOOL switchState);

// Track Event
@optional
@property (nonatomic, copy, nullable) void(^trackEventSegmentBlock)(NSUInteger index);
@property (nonatomic, copy, nullable) void(^trackEventSwitchBlock)(BOOL switchState);

@end

@interface ACCAdvancedRecordSettingItem : NSObject <ACCPopupTableViewDataItemProtocol>

@end
