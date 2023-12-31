//
//  CJPayAuthVerifiedHalfView.h
//  BDAlogProtocol
//
//  Created by qiangang on 2020/7/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayStyleButton;
@class CJPayAuthAgreementContentModel;
@interface CJPayAuthVerifiedHalfView : UIView

typedef void (^CJPayAuthVerifiedViewAction)(void);
typedef void (^CJPayAuthVerifiedViewNotMeAction)(NSString *logoutUrl);
typedef void (^CJPayAuthVerifiedViewProtocolClickedAction)(UILabel * _Nonnull label, NSString * _Nonnull protocolName, NSRange range, NSInteger index);

@property (nonatomic, strong, readonly) CJPayStyleButton *authButton;
@property (nonatomic, copy) CJPayAuthVerifiedViewAction closeBlock;
@property (nonatomic, copy) CJPayAuthVerifiedViewAction logoutBlock;
@property (nonatomic, copy) CJPayAuthVerifiedViewNotMeAction notMeBlock;
@property (nonatomic, copy) CJPayAuthVerifiedViewAction authVerifiedBlock;
@property (nonatomic, copy) CJPayAuthVerifiedViewProtocolClickedAction protocolClickedBlock;
@property (nonatomic, copy, nullable) CJPayAuthVerifiedViewAction clickExclamatoryMarkBlock;

- (instancetype)initWithStyle:(NSDictionary*)style;
- (void)updateWithModel:(CJPayAuthAgreementContentModel *)model;
- (void)hideExclamatoryMark:(BOOL)isHidden;

@end

NS_ASSUME_NONNULL_END
