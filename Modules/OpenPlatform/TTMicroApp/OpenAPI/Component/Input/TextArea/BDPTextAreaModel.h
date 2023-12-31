//
//  BDPTextAreaModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <OPFoundation/BDPBaseJSONModel.h>
#import "BDPTextAreaStyleModel.h"
#import "BDPTextAreaPlaceHolderStyleModel.h"


@interface BDPTextAreaModel : BDPBaseJSONModel

@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL autoSize;
@property (nonatomic, assign) BOOL confirm;
@property (nonatomic, assign) BOOL fixed;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, copy) NSString * _Nullable data;
@property (nonatomic, copy) NSString * _Nullable value;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) BDPTextAreaPlaceHolderStyleModel *placeholderStyle;
@property (nonatomic, strong) BDPTextAreaStyleModel *style;
/// 键盘弹起时，是否自动上推页面
@property (nonatomic, assign) BOOL adjustPosition;

/// 是否显示键盘上方带有”完成“按钮那一栏
@property (nonatomic, assign) BOOL showConfirmBar;

// 以下3个参数只有showTextAreaKeyboard时会单独传输，单独使用，并非来自JSON的全量解析
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, assign) NSInteger selectionStart;
@property (nonatomic, assign) NSInteger selectionEnd;

// 是否取消系统textView自带的padding，上8下8左5右5
@property (nonatomic, assign) BOOL disableDefaultPadding;

@property (nonatomic, assign) BOOL focus;
@property (nonatomic, assign) BOOL autoBlur;

- (nullable instancetype)initWithDictionary:(NSDictionary * _Nonnull)dict error:(NSError *__autoreleasing *)err;
@end

