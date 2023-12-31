//
//  BDTuringToast.m
//  BDTuring
//
//  Created by bob on 2019/9/27.
//

#import "BDTuringToast.h"

static UILabel *turing_toastView(NSString *message) {
    UILabel *messageView = [UILabel new];
    messageView.layer.cornerRadius = 8;
    messageView.layer.masksToBounds = YES;
    messageView.backgroundColor = [UIColor blackColor];
    messageView.numberOfLines = 0;
    messageView.textAlignment = NSTextAlignmentCenter;
    messageView.textColor = [UIColor whiteColor];
    UIFont *font = [UIFont systemFontOfSize:15];
    messageView.font = font;
    messageView.alpha = 0.8;

    CGRect rect = [message boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:font}
                                        context:nil];
    CGFloat width = rect.size.width + 20;
    CGFloat height = rect.size.height + 20;
    messageView.frame = CGRectMake(0, 0, width, height);
    messageView.text = message;

    return messageView;
}

void turing_toastShow(UIView *view, NSString *message, dispatch_block_t finish) {
    UILabel *toastView = turing_toastView(message);
    CGSize parent = view.frame.size;
    CGSize toast = toastView.frame.size;
    toastView.frame = CGRectMake((parent.width - toast.width)/2,
                                 (parent.height - toast.height)/2,
                                 toast.width,
                                 toast.height);
    [view addSubview:toastView];
    [UIView animateWithDuration:0.2f delay:2.0f options:(UIViewAnimationOptionCurveLinear) animations:^{
        toastView.alpha = 0;
    } completion:^(BOOL finished) {
        [toastView removeFromSuperview];
        if (finish) {
            finish();
        }
    }];
}
