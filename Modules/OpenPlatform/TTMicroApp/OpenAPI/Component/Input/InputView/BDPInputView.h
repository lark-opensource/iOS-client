//
//  BDPInputView.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <UIKit/UIKit.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import "BDPInputViewModel.h"
#import "BDPComponentManager.h"
#import "BDPInputEventDelegate.h"
@interface BDPInputView : UITextField <BDPComponentViewProtocol>

@property (nonatomic, assign) NSInteger webViewID;
@property (nonatomic, assign) NSInteger componentID;
@property (nonatomic, strong) BDPInputViewModel *model;
@property (nonatomic, weak) id<BDPInputEventDelegate> eventDelegate; // 新框架事件代理

@property (nonatomic, assign, readonly) BOOL isNativeComponent; // 是否是用的新框架

@property (nonatomic, weak) UIView *page;
@property (nonatomic, weak) BDPJSBridgeEngine engine;

// 新版Plugin，不直接依赖engine
@property (nonatomic, copy, nullable) void (^fireWebviewEventBlock)(NSString *event, NSDictionary *data);
@property (nonatomic, copy, nullable) void (^fireAppServiceEventBlock)(NSString *event, NSDictionary *data);

- (instancetype)initWithModel:(BDPInputViewModel *)model isNativeComponent:(BOOL)isNativeComponent isOverlay:(BOOL)isOverlay;

// Update With Dictionary
- (void)updateWithDictionary:(NSDictionary *)dict;

// Update Cursor & Selection
- (void)updateCursorAndSelection:(BDPInputViewModel *)model;
/// UITextFiled 右对齐时，如果输入空格光标不会动，因此会替换成\u00a0，在使用的时候需要换回来
- (NSString *)resultText;
// 根据fontSize通知JS更新高度
- (void)updateHeight;

- (void)setOverlayStatus:(BOOL)isShow;

@end
