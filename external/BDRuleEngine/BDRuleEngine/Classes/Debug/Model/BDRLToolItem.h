//
//  BDRLToolItem.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDRLToolItemType) {
    BDRLToolItemTypeMore,
    BDRLToolItemTypeSwitch,
    BDRLToolItemTypeAction,
    BDRLToolItemTypeInput,
    BDRLToolItemTypeButton,
    BDRLToolItemTypeText,
    BDRLToolItemTypeStrategyButton
};

typedef NS_ENUM(NSUInteger, BDRLToolItemInputType) {
    BDRLToolItemInputTypeString,
    BDRLToolItemInputTypeDictionary,
    BDRLToolItemInputTypeArray
};

@interface BDRLToolItem : NSObject

@property (nonatomic, copy, nullable) NSString *itemTitle;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, assign) BDRLToolItemType itemType;
@property (nonatomic, assign) BDRLToolItemInputType inputType;
@property (nonatomic, assign) BOOL inputDisable;
@property (nonatomic, strong, nullable) Class nextViewControllerClass;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy, nullable) void (^action)(void);

@end

NS_ASSUME_NONNULL_END
