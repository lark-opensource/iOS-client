//
//  CJPayCustomTextFieldConfigration.h
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import <UIKit/UIKit.h>
#import "CJPayCustomTextFieldContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCustomTextFieldConfigration : NSObject<CJPayCustomTextFieldDelegate>

@property (nonatomic,copy, readonly) NSString *userInputContent;
@property (nonatomic, weak) CJPayCustomTextFieldContainer *tfContainer;

@property (nonatomic, assign) BOOL isLegal;
@property (nonatomic, copy) void(^textFieldEndEditCompletionBlock)(BOOL isLegal);

@property (nonatomic, copy) NSString *errorMsg; //track event

- (void)bindTextFieldContainer:(CJPayCustomTextFieldContainer *)tfContainer;
- (BOOL)contentISValid;
- (void)setSelectedRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
