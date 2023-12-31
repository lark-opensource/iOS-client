//
//  ACCNewYearWishTextEditView.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/3.
//

#import <UIKit/UIKit.h>

@interface ACCNewYearWishTextEditView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t dismissBlock;
@property (nonatomic, copy, nullable) void(^onTitleSelected)(NSString *, NSInteger);

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy, nullable) NSArray<NSString *> *titles;

- (void)performAnimation:(BOOL)show;

@end
