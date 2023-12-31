//
//  ACCSearchBar.h
//  Aweme
//
//  Created by bytedance on 2017/11/8.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ACCSearchBarClearButtonTappedBlockType)(void);
typedef void (^ACCSearchBarBeginEditBlockType)(void);
typedef void (^ACCSearchBarEndEditBlockType)(void);

typedef NS_ENUM(NSInteger, ACCSearchBarColorStyle) {
    ACCSearchBarColorStyleNormal = 0,
    ACCSearchBarColorStyleD
};

@interface ACCSearchBar : UISearchBar

@property (nonatomic, weak) UITextField *ownSearchField;
@property (nonatomic, assign) BOOL needShowKeyBoard;
@property (nonatomic, assign) BOOL banAutoSearchTextPositionAdjustment;
@property (nonatomic, copy) ACCSearchBarClearButtonTappedBlockType clearButtonTappedBlock;
@property (nonatomic, copy) ACCSearchBarBeginEditBlockType beginEditBlock;
@property (nonatomic, copy) ACCSearchBarEndEditBlockType endEditBlock;

- (instancetype)initWithFrame:(CGRect)frame colorStyle:(ACCSearchBarColorStyle)style;

@end
