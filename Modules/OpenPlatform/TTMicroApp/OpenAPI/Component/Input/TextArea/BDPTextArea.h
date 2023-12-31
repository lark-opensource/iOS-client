//
//  BDPTextArea.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <UIKit/UIKit.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import "BDPTextAreaModel.h"
#import "BDPComponentManager.h"

// ⚠️同层渲染组件
@interface BDPTextArea : UITextView

@property (nonatomic, assign) NSInteger webViewID;
@property (nonatomic, copy) NSString *componentID;
@property (nonatomic, strong) BDPTextAreaModel *model;

@property (nonatomic, weak) UIView *page;
@property (nonatomic, assign) CGRect pageOriginFrame;
// 新版Plugin灰度完成后，该engine要移除
@property (nonatomic, weak) BDPJSBridgeEngine engine;

// 新版Plugin，不直接依赖engine
@property (nonatomic, copy, nullable) void (^fireWebviewEventBlock)(NSString * _Nullable event, NSDictionary * _Nullable data);
@property (nonatomic, copy, nullable) void (^fireAppServiceEventBlock)( NSString * _Nullable event, NSDictionary * _Nullable data);

- (instancetype)initWithModel:(BDPTextAreaModel *)model;

- (void)updateWithNewModel:(BDPTextAreaModel * _Nonnull)model;
// Update With Dictionary
- (void)updateWithDictionary:(NSDictionary * _Nullable)dict;

// Update Cursor & Selection
- (void)updateCursorAndSelection:(BDPTextAreaModel *)model;

// Update Height For AutoSize
- (void)updateHeightForAutoSize:(BDPTextAreaModel *)model;
- (void)updateAutoSizeHeight;

@end
