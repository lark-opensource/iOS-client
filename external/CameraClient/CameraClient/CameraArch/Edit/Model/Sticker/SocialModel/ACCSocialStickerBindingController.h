//
//  ACCSocialStickerBindingController.h
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import "ACCSocialStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSString *ACCSocialStickerInputFilteredStringWithString(NSString *string) {
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@protocol ACCSocialStickerBindingDelegate;

@interface ACCSocialStickerBindingController : NSObject

ACCSocialStickerObjUsingCustomerInitOnly;
- (instancetype)initWithTextInput:(UITextField *)textInput
                     stickerModel:(ACCSocialStickerModel *)stickerModel
                         delegate:(id<ACCSocialStickerBindingDelegate>)delegate;

- (BOOL)bindingWithMentionModel:(ACCSocialStickeMentionBindingModel *_Nullable)bindingUserModel;
- (BOOL)bindingWithHashTagModel:(ACCSocialStickeHashTagBindingModel *_Nullable)hashTagModel;

+ (NSString *)complianceStringWithString:(NSString *)string;

@end

@protocol ACCSocialStickerBindingDelegate <UITextFieldDelegate>

@required
- (void)bindingController:(ACCSocialStickerBindingController *)bindingController
            onTextChanged:(UITextField *)textField;

- (void)bindingControllerOnMentionBindingDataChanged:(ACCSocialStickerBindingController *)bindingController;

- (void)bindingControllerOnSearchKeywordChanged:(ACCSocialStickerBindingController *)bindingController;

@end

NS_ASSUME_NONNULL_END
