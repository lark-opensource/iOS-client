//
// Created by 张海阳 on 2020/3/11.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayInvestResultPayInfoViewRowData : NSObject

@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *buttonTitle;
@property (nonatomic, copy) NSString *iconUrlStr;
@property (nonatomic, copy, nullable) void (^buttonAction)(CJPayInvestResultPayInfoViewRowData *);

@property (nonatomic, strong) UIFont *font;

- (CGFloat)rowHeight;
- (CGSize)detailRectSize;

@end


@interface CJPayInvestResultPayInfoCell : UITableViewCell

@property (nonatomic, assign, class, readonly) CGFloat minHeight;
@property (nonatomic, assign, class, readonly) CGFloat safeDistance;
@property (nonatomic, strong, readonly) CJPayInvestResultPayInfoViewRowData *rowData;

@property (nonatomic, assign) CGFloat realHeight;

- (void)configWith:(CJPayInvestResultPayInfoViewRowData *)rowData;
- (void)p_setupUI;              // only for override
- (void)p_makeConstraints;      // only for override

@end


@interface CJPayInvestResultPayInfoWithButtonCell : CJPayInvestResultPayInfoCell

@end


@interface CJPayRechargeResultPayInfoView : UIView

@property (nonatomic, copy, readonly) NSArray<CJPayInvestResultPayInfoViewRowData *> *dataSource;

- (void)reloadWith:(NSArray<CJPayInvestResultPayInfoViewRowData *> *)dataSource;

@end

NS_ASSUME_NONNULL_END
