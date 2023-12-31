//
//  CJPayBindCardTopHeaderViewModel.m
//  Pods
//
//  Created by 孟源 on 2022/8/2.
//

#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBindCardManager.h"
#import <BDWebImage/BDWebImage.h>

@implementation CJPayBindCardTopHeaderViewModel

- (NSMutableAttributedString *)getAttributedStringWithCompletion:(void (^)(NSMutableAttributedString * _Nullable attributedStr))completion {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    if (Check_ValidString(self.bankIcon)) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.bounds = CGRectMake(0, -3, 22, 22);
        attachment.image = [UIImage cj_imageWithColor:[UIColor cj_skeletonScreenColor]];
        NSAttributedString *imageAttr = [NSAttributedString attributedStringWithAttachment:attachment];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        paragraphStyle.minimumLineHeight = 31;
        NSMutableAttributedString *bindStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@"%@ ") ,self.preTitle] attributes:@{
            NSFontAttributeName : [UIFont cj_boldFontWithoutFontScaleOfSize:22],
            NSForegroundColorAttributeName : [UIColor cj_161823ff],
            NSParagraphStyleAttributeName:paragraphStyle
        }];
        NSMutableAttributedString *bankStr = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@" %@"), self.title]  attributes:@{
            NSFontAttributeName : [UIFont cj_boldFontWithoutFontScaleOfSize:22],
            NSForegroundColorAttributeName : [UIColor cj_161823ff],
            NSParagraphStyleAttributeName:paragraphStyle
        }];
        [attributedString appendAttributedString:bindStr];
        [attributedString appendAttributedString:imageAttr];
        [attributedString appendAttributedString:bankStr];
        
        NSMutableAttributedString *amountAttr = nil;
        if (Check_ValidString(self.orderAmount)) {
            NSString *amountStr = [@" ¥" stringByAppendingString:CJString(self.orderAmount)];
            amountAttr = [self getAmountAttributedString:amountStr];
            [attributedString appendAttributedString:amountAttr];
        }
        [BDWebImageManager.sharedManager requestImage:[NSURL URLWithString:self.bankIcon]
                                              options:BDImageRequestDefaultPriority
                                             complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            void(^finishBlock)(void) = ^{
                if (image) {
                    attachment.image = image;
                    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] init];
                    [attributedStr appendAttributedString:bindStr];
                    [attributedStr appendAttributedString:imageAttr];
                    [attributedStr appendAttributedString:bankStr];
                    if (amountAttr) {
                        [attributedStr appendAttributedString:amountAttr];
                    }
                    CJ_CALL_BLOCK(completion, attributedStr);
                } else {
                    CJ_CALL_BLOCK(completion, nil);
                }
            };
            
            if ([NSThread isMainThread]) {
                finishBlock();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finishBlock();
                });
            }
        }];
    }
    return attributedString;
}

- (NSMutableAttributedString *)getAmountAttributedString:(NSString *)amount {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.minimumLineHeight = 31;
    NSMutableAttributedString *amountStr = [[NSMutableAttributedString alloc]
        initWithString:CJPayLocalizedStr(amount)  attributes:@{
        NSFontAttributeName : [UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:26],
        NSForegroundColorAttributeName : [UIColor cj_161823ff],
        NSParagraphStyleAttributeName:paragraphStyle,
        NSBaselineOffsetAttributeName:@(-1)
    }];
    return amountStr;
}

@end
