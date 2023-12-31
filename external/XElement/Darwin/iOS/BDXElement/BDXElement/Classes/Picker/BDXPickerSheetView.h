//
//  BDXPickerSheetView.h
//  AWEAppConfigurations
//
//  Created by annidy on 2020/5/8.
//

#import "BDPickerSource.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXPickerSheetView;

@protocol BDXPickerSheetViewDelegate <NSObject>

- (void)onPickerSheetChanged:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res;

- (void)onPickerSheetCancel:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res;

- (void)onPickerSheetConfirm:(BDXPickerSheetView *)picker withResult:(NSDictionary *)res;

@end


@interface BDXPickerSheetView : UIView

@property (nonatomic,assign) BOOL disabled;

@property (weak) id<BDXPickerSheetViewDelegate> delegate;

@property (nonatomic) BDXPickerSource *dataSource;

@property (nonatomic, assign) BOOL showInWindow;

- (void)showInView:(UIView *)view;

- (void)dismiss;

- (NSArray<NSNumber *> *)selectedIndexs;

@end

NS_ASSUME_NONNULL_END
