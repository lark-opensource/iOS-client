//
//  DYOpenAlertViewController.h
//  Pods
//
//  Created by bytedance on 2022/3/9.
//

@interface DouyinOpenConfirmViewController:UIViewController

typedef void (^ConfirmCallback)(void);

@property (nonatomic, strong) IBOutlet UIView *alertView;
@property (nonatomic, copy) ConfirmCallback callBack;


@end
