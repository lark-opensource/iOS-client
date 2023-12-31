//
//  ACCFlowerPanelEffectListModel.h
//  Indexer
//
//  Created by xiafeiyu on 11/15/21.
//

#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreationKitArch/ACCURLModelProtocol.h>

typedef NS_ENUM(NSInteger, ACCFlowerEffectType) {
    ACCFlowerEffectTypeInvalid = -1,
    ACCFlowerEffectTypeProp = 0,
    ACCFlowerEffectTypeScan = 1, // 扫一扫
    ACCFlowerEffectTypePhoto = 2, // 拍照
    ACCFlowerEffectTypeRecognition = 3 // 物种识别
};

@interface ACCFlowerPanelURLModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *URI;
@property (nonatomic, copy, nullable) NSArray<NSString *> *URLList;
@property (nonatomic, assign) NSInteger dataSize;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, copy, nullable) NSString *URLKey;
@property (nonatomic, copy, nullable) NSString *fileHash;
@property (nonatomic, copy, nullable) NSString *fileCS;
@property (nonatomic, copy, nullable) NSString *playerAccessKey;

@end

@class IESEffectModel;

@interface ACCFlowerPanelEffectModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *effectID;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, strong, nullable) ACCFlowerPanelURLModel *iconURL;
@property (nonatomic, assign) NSInteger isLocked;
@property (nonatomic, copy, nullable) NSString *editTaskID;
@property (nonatomic, copy, nullable) NSString *publishTaskID;
@property (nonatomic, assign) ACCFlowerEffectType dType;
@property (nonatomic, copy, nullable) NSString *extra;

// local property
@property (nonatomic, strong, nullable) IESEffectModel *effect;

+ (instancetype)panelEffectModelFromIESEffectModel:(nullable IESEffectModel *)model;

// flower shoot prop
- (NSDictionary *)flowerPhotoPropEffectPanelInfo;

@end

// 预约期间道具列表

@interface ACCFlowerPanelPreCampainEffectListModel : ACCBaseApiModel

@property (nonatomic, copy, nullable) NSArray<ACCFlowerPanelEffectModel *> *effectList;
@property (nonatomic, assign) NSInteger landingIndex;

@end

// 正式活动期间道具列表
@interface ACCFlowerPanelEffectListModel : ACCBaseApiModel

@property (nonatomic, copy, nullable) NSArray<ACCFlowerPanelEffectModel *> *leftList;
@property (nonatomic, copy, nullable) NSArray<ACCFlowerPanelEffectModel *> *rightList;

@end
