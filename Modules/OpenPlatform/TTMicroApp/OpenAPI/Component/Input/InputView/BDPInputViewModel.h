//
//  BDPInputViewModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <OPFoundation/BDPBaseJSONModel.h>
#import "BDPInputViewStyleModel.h"
#import "BDPInputViewPlaceHolderStyleModel.h"

@interface BDPInputViewModel : BDPBaseJSONModel

@property (nonatomic, assign) BOOL fixed;
@property (nonatomic, assign) BOOL password;
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, assign) NSInteger selectionStart;
@property (nonatomic, assign) NSInteger selectionEnd;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, copy) NSString *type; //text, number, digit, idcard
@property (nonatomic, copy) NSString *data;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *confirmType;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) BDPInputViewPlaceHolderStyleModel *placeholderStyle;
@property (nonatomic, strong) BDPInputViewStyleModel *style;
@property (nonatomic, assign) BOOL autoFocus; // 自动获取焦点
@property (nonatomic, assign) BOOL focus; // 是否获取焦点
@property (nonatomic, assign) BOOL disabled; // 设置input是否可用
/// 键盘弹起时，是否自动上推页面
@property (nonatomic, assign) BOOL adjustPosition;

- (NSAttributedString *)attributedPlaceholder;

@end
