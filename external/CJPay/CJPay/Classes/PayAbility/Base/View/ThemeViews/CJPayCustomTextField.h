//
//  CJPayCustomTextField.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayCustomTextFieldDelegate <NSObject>

- (void)textFieldBeginEdit;
- (void)textFieldEndEdit;
- (void)textFieldWillClear;
- (void)textFieldContentChange;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@optional
- (CGRect)textFieldRightViewRectForBounds:(CGRect)bounds;

@end

@interface CJPayCustomTextField : UITextField

@property (nonatomic,assign) NSInteger separateCount;
@property (nonatomic,copy) NSArray *separateArray;
@property (nonatomic,assign) NSInteger limitCount;
@property (nonatomic,assign) BOOL supportSeparate;
@property (nonatomic,strong) NSCharacterSet *supportCharacterSet;
@property (nonatomic,copy, readonly) NSString *userInputContent;
@property (nonatomic,weak) id<CJPayCustomTextFieldDelegate> textFieldDelegate;
@property (nonatomic,assign) NSInteger locationIndex;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

- (NSString*)changeStringWithOperateString:(NSString*)string
                          withOperateRange:(NSRange)range
                          withOriginString:(NSString*)originString;

@end

NS_ASSUME_NONNULL_END
