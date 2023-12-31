//
//  BDPPluginPickerCustomImpl.m
//  TTMicroAppImpl
//
//  Created by MacPu on 2018/12/27.
//

#import "BDPPluginPickerCustomImpl.h"
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/BDPPickerView.h>
#import <OPFoundation/BDPDatePickerView.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMAAddressManager.h>
#import <OPFoundation/BDPRegionPickerView.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/OPAlertContainerController.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/OPFoundation-Swift.h>

@interface BDPPluginPickerCustomImpl() <BDPPickerPluginDelegate, BDPPickerViewDelegate, BDPDatePickerViewDelegate>

@property (nonatomic, copy) void (^pickerSelectedCallback)(NSInteger seletedRow, NSInteger column);
@property (nonatomic, copy) void (^pickerResultCallback)(BOOL isCanceled, NSArray<NSNumber *> *selectedRow, BDPPickerPluginModel *model);
@property (nonatomic, copy) void (^datePickerResultCallback)(BOOL isCanceled, NSDate *time);
@property (nonatomic, strong) BDPPickerView *pickerView;
@property (nonatomic, strong) BDPDatePickerView *datePickerView;
@property (nonatomic, strong) BDPRegionPickerView *regionPickerView;

@property (nonatomic, strong) OPAlertContainerController *pickerContainer;
@property (nonatomic, strong) OPAlertContainerController *datePickerContainer;
@property (nonatomic, strong) OPAlertContainerController *regionPickerContainer;
@property (nonatomic, strong) OPViewSizeClass *viewSizeClass;
@end

@implementation BDPPluginPickerCustomImpl


+ (id<BDPBasePluginDelegate>)sharedPlugin
{
    static BDPPluginPickerCustomImpl *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BDPPluginPickerCustomImpl alloc] init];
    });
    return sharedInstance;
}

- (void)bdp_showPickerViewWithModel:(BDPPickerPluginModel *)model
                     fromController:(UIViewController *)fromController
             pickerSelectedCallback:(void (^)(NSInteger, NSInteger))pickerSelectedCallback
                         completion:(void (^)(BOOL, NSArray<NSNumber *> *, BDPPickerPluginModel *))completion
{
    BDPLogInfo(@"bdp_showPickerView, model=%@", model);
    UIViewController *topVC = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController;
    if (!topVC || !topVC.view) {
        BDPLogInfo(@"bdp_showPickerViewWithModel, topVC / topVC.view is nil");
        return;
    }
    [self setupPickerViewWithModel:model fromController:fromController];
    self.viewSizeClass = [[OPViewSizeClass alloc] init];
    WeakSelf;
    [self.viewSizeClass traitCollectionChangeWithView:topVC.view didChange:^(UITraitCollection * _Nonnull traitCollection) {
        StrongSelf;
        if ([self.pickerView superview]){
            [self.pickerView removeFromSuperview];
        }
        if (self.pickerContainer) {
            [self.pickerContainer dismissViewControllerWithAnimated:NO completion:^{
                [self setupPickerViewWithModel:model fromController:fromController];
            }];
        } else {
            [self setupPickerViewWithModel:model fromController:fromController];
        }

    }];
    self.pickerSelectedCallback = pickerSelectedCallback;
    self.pickerResultCallback = completion;
}

- (void)setupPickerViewWithModel:(BDPPickerPluginModel *)model
                  fromController:(UIViewController *)fromController
{
    UIViewController *topVC = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController;
    if (!topVC || !topVC.view) {
        BDPLogInfo(@"setupPickerViewWithModel, topVC / topVC.view is nil");
        return;
    }
    if (BDPDeviceHelper.isPadDevice && [OPViewSizeClass sizeClassWithWindow:topVC.view.window] == UIUserInterfaceSizeClassRegular) {
        BDPPickerView *pickerView = [[BDPPickerView alloc] initWithFrame:CGRectMake(0, 0, 375, 256) style:BDPPickerViewStyleAlert];
        pickerView.delegate = self;
        [pickerView updateWithModel:model];
        OPAlertContainerController *alert = [[OPAlertContainerController alloc] init];
        [alert updateAlertView:pickerView size:pickerView.frame.size];
        pickerView.backgroundColor = [UIColor blueColor];
        [topVC presentViewController:alert animated:YES completion:nil];
        WeakSelf;
        alert.tapBackgroud = ^{
            StrongSelf;
            self.viewSizeClass = nil;
        };
        self.pickerContainer = alert;
        self.pickerView = pickerView;

    } else {
        BDPPickerView *pickerView = [[BDPPickerView alloc] initWithFrame:topVC.view.bounds];
        pickerView.delegate = self;
        [pickerView updateWithModel:model];
        [pickerView showInView:topVC.view];
        self.pickerView = pickerView;
    }
}

- (void)bdp_updatePickerWithModel:(BDPPickerPluginModel *)model animated:(BOOL)animated
{
    BDPLogInfo(@"bdp_updatePicker, model=%@", model);
    BDPPickerPluginModel *pickerModel = self.pickerView.model;
    pickerModel.selectedRows = [self.pickerView selectedIndexs];
    [pickerModel updateWithModel:model];
    
    [self.pickerView updateWithModel:pickerModel];
}

- (void)bdp_showDatePickerViewWithModel:(BDPDatePickerPluginModel *)model fromController:(UIViewController *)fromController completion:(void (^)(BOOL, NSDate *))completion
{
    BDPLogInfo(@"bdp_showDatePickerView, model=%@", model);
    UIViewController *topVC = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController;
    if (!topVC || !topVC.view) {
        BDPLogInfo(@"bdp_showDatePickerViewWithModel, topVC / topVC.view is nil");
        return;
    }
    self.datePickerResultCallback = completion;
    [self setupDatePickerViewWithModel:model fromController:fromController];
    self.viewSizeClass = [[OPViewSizeClass alloc] init];

    WeakSelf;
    [self.viewSizeClass traitCollectionChangeWithView:topVC.view didChange:^(UITraitCollection * _Nonnull traitCollection) {
        StrongSelf;
        [self.datePickerView removeFromSuperview];
        if (self.datePickerContainer) {
            [self.datePickerContainer dismissViewControllerWithAnimated:NO completion:^{
                [self setupDatePickerViewWithModel:model fromController:fromController];
            }];
        } else {
            [self setupDatePickerViewWithModel:model fromController:fromController];
        }

    }];

}

- (void)setupDatePickerViewWithModel:(BDPDatePickerPluginModel *)model fromController:(UIViewController *)fromController
{
    UIViewController *topVC = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController;
    if (!topVC || !topVC.view) {
        BDPLogInfo(@"setupDatePickerViewWithModel, topVC / topVC.view is nil");
        return;
    }

    if (BDPDeviceHelper.isPadDevice && [OPViewSizeClass sizeClassWithWindow:topVC.view.window] == UIUserInterfaceSizeClassRegular) {
        BDPDatePickerView *pickerView = [[BDPDatePickerView alloc] initWithFrame:CGRectMake(0, 0, 375, 256) model:model style:BDPDatePickerViewStyleAlert];
        pickerView.delegate = self;
        OPAlertContainerController *alert = [[OPAlertContainerController alloc] init];
        [alert updateAlertView:pickerView size:pickerView.frame.size];
        pickerView.backgroundColor = [UIColor blueColor];
        [topVC presentViewController:alert animated:YES completion:nil];
        WeakSelf;
        alert.tapBackgroud = ^{
            StrongSelf;
            self.viewSizeClass = nil;
        };
        self.datePickerContainer = alert;
        self.datePickerView = pickerView;

    } else {
        BDPDatePickerView *pickerView = [[BDPDatePickerView alloc] initWithFrame:topVC.view.bounds model:model];
        pickerView.delegate = self;
        [pickerView showInView:topVC.view];
        self.datePickerView = pickerView;
    }

}
- (void)bdp_showRegionPickerViewWithModel:(BDPRegionPickerPluginModel *)model fromController:(UIViewController *)fromController completion:(void (^)(BOOL, BDPAddressPluginModel *))completion
{
    UIView *topView = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController.view;
    [self setupRegionPickerViewWithModel:model fromController:fromController completion:completion];
    self.viewSizeClass = [[OPViewSizeClass alloc] init];
    WeakSelf;
    [self.viewSizeClass traitCollectionChangeWithView:topView didChange:^(UITraitCollection * _Nonnull traitCollection) {
        StrongSelf;
        [self.regionPickerView removeFromSuperview];
        if (self.regionPickerContainer) {
            [self.regionPickerContainer dismissViewControllerWithAnimated:NO completion:^{
                [self setupRegionPickerViewWithModel:model fromController:fromController completion:completion];
            }];
        } else {
            [self setupRegionPickerViewWithModel:model fromController:fromController completion:completion];
        }

    }];

}



- (void)setupRegionPickerViewWithModel:(BDPRegionPickerPluginModel *)model fromController:(UIViewController *)fromController completion:(void (^)(BOOL, BDPAddressPluginModel *))completion
{
    UIView *topView = [BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController.view;
    if (!topView) {
        BDPLogInfo(@"setupRegionPickerViewWithModel, topView is nil");
        return;
    }

    if (BDPDeviceHelper.isPadDevice && [OPViewSizeClass sizeClassWithWindow:topView.window] == UIUserInterfaceSizeClassRegular) {
        OPAlertContainerController *alert = [[OPAlertContainerController alloc] init];

        BDPRegionPickerView *pickerView = [[BDPRegionPickerView alloc] initWithFrame:CGRectMake(0, 0, 375, 256) model:model style:BDPRegionPickerViewStyleAlert];
        WeakSelf;
        WeakObject(alert);
        pickerView.confirmBlock = ^(BDPAddressPluginModel *address) {
            StrongSelf;
            StrongObject(alert);
            if (completion) {
                completion(NO, address);
            }
            [alert dismissViewController];
            self.viewSizeClass = nil;
        };
        pickerView.cancelBlock = ^{
            StrongSelf;
            StrongObject(alert);
            if (completion) {
                completion(YES, nil);
            }
            [alert dismissViewController];
            self.viewSizeClass = nil;
        };
        [alert updateAlertView:pickerView size:pickerView.frame.size];
        pickerView.backgroundColor = [UIColor blueColor];
        [[BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:fromController.view.window]].topViewController presentViewController:alert animated:YES completion:nil];
        alert.tapBackgroud = ^{
            StrongSelf;
            self.viewSizeClass = nil;
        };
        self.regionPickerContainer = alert;
        self.regionPickerView = pickerView;

    } else {
        BDPRegionPickerView *pickerView = [[BDPRegionPickerView alloc] initWithFrame:topView.bounds model:model];
        WeakSelf;
        pickerView.confirmBlock = ^(BDPAddressPluginModel *address) {
            StrongSelf;
            if (completion) {
                completion(NO, address);
            }
            self.viewSizeClass = nil;
        };
        pickerView.cancelBlock = ^{
            StrongSelf;
            if (completion) {
                completion(YES, nil);
            }
            self.viewSizeClass = nil;
        };
        [pickerView showInView:topView];
        self.regionPickerView = pickerView;

    }

}

#pragma mark - BDPPickerViewDelegate

- (void)didCancelPicker:(BDPPickerView *)picker
{
    if (_pickerResultCallback) {
        _pickerResultCallback(YES, nil, nil);
    }
    [_pickerContainer dismissViewController];
    self.viewSizeClass = nil;
}

- (void)picker:(BDPPickerView *)picker didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (_pickerSelectedCallback) {
        _pickerSelectedCallback(row, component);
    }
}

- (void)picker:(BDPPickerView *)picker didConfirmOnIndexs:(NSArray<NSNumber *> *)indexs
{
    BDPPickerPluginModel *model = picker.model;
    if (_pickerResultCallback) {
        _pickerResultCallback(NO, indexs, model);
    }
    [_pickerContainer dismissViewController];
    self.viewSizeClass = nil;

}

#pragma mark - BDPDatePickerViewDeleageta

- (void)didCancelDatePicker:(BDPDatePickerView *)picker
{
    if (_datePickerResultCallback) {
        _datePickerResultCallback(YES, nil);
    }
    [_datePickerContainer dismissViewController];
    self.viewSizeClass = nil;
}

- (void)datePicker:(BDPDatePickerView *)picker didSelectedDate:(NSDate *)time
{
    if (_datePickerResultCallback) {
        _datePickerResultCallback(NO, time);
    }
    [_datePickerContainer dismissViewController];
    self.viewSizeClass = nil;
}

@end
