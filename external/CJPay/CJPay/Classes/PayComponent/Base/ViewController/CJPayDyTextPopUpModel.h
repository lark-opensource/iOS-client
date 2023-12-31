//
//  CJPayDyTextPopUpModel.h
//  Pods
//
//  Created by youerwei on 2021/11/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayTextPopUpType) {
    // 详细样式: https://www.figma.com/file/4Jy7kIr6qd2dSLgkhxiMYr/%E7%BB%91%E5%8D%A1%2F%E5%AE%9E%E5%90%8D%2F%E7%AE%A1%E7%90%86?node-id=4061%3A18479
    // 单button
    CJPayTextPopUpTypeDefault = 1,
    // 横向双button
    // mainOperation为右侧button文案
    CJPayTextPopUpTypeHorizontal,
    // 纵向双button
    CJPayTextPopUpTypeVertical,
    // 纵向三button
    CJPayTextPopUpTypeLongVertical,
};

typedef NS_ENUM(NSUInteger, CJPayTextPopUpContentAlignmentType) {
    CJPayTextPopUpContentAlignmentTypeDefault,
    CJPayTextPopUpContentAlignmentTypeLeft,
    CJPayTextPopUpContentAlignmentTypeCenter,
    CJPayTextPopUpContentAlignmentTypeRight
};

@class CJPayDyTextPopUpViewController;
@interface CJPayDyTextPopUpModel : NSObject

@property (nonatomic, assign) CJPayTextPopUpType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) CJPayTextPopUpContentAlignmentType contentAlignment;
@property (nonatomic, copy) NSString *mainOperation;
@property (nonatomic, strong) UIColor *secondOperationColor;
@property (nonatomic, copy) NSString *secondOperation;
@property (nonatomic, copy) NSString *thirdOperation;
@property (nonatomic, strong) UIColor *mainOperationColor;
@property (nonatomic, copy) void(^didClickMainOperationBlock)(void);
@property (nonatomic, copy) void(^didClickSecondOperationBlock)(void);
@property (nonatomic, copy) void(^didClickThirdOperationBlock)(void);

@end

NS_ASSUME_NONNULL_END
