//
//  BDPPickerView.h
//  TTMicroAppImpl
//
//  Created by MacPu on 2018/12/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPPickerView, BDPPickerPluginModel;

@protocol BDPPickerViewDelegate <NSObject>

- (void)didCancelPicker:(BDPPickerView *)picker;
- (void)picker:(BDPPickerView *)picker didConfirmOnIndexs:(NSArray<NSNumber *> *)indexs;
- (void)picker:(BDPPickerView *)picker didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end

typedef NS_ENUM(NSInteger, BDPPickerViewType) {
    BDPPickerViewTypeNormal,
    BDPPickerViewTypeMulti
};

typedef NS_ENUM(NSInteger, BDPPickerViewStyle) {
    BDPPickerViewStylePicker,
    BDPPickerViewStyleAlert
};

@interface BDPPickerView : UIView

@property (nonatomic, assign, readonly) BDPPickerViewType type;
@property (nonatomic, weak) id<BDPPickerViewDelegate> delegate;
@property (nonatomic, strong, readonly) BDPPickerPluginModel *model;
- (instancetype)initWithFrame:(CGRect)frame style:(BDPPickerViewStyle)style;
- (void)updateWithModel:(BDPPickerPluginModel *)model;
- (void)showInView:(UIView *)view;
- (NSArray<NSNumber *> *)selectedIndexs;
- (void)showAlertInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
