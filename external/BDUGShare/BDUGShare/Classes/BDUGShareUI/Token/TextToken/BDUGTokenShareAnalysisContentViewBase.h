//
//  BDUGTokenShareAnalysisContentViewBase.h
//  Article
//
//  Created by zengzhihui on 2018/6/1.
//

#import <Foundation/Foundation.h>

@class BDUGTokenShareAnalysisResultModel;

@interface BDUGTokenShareAnalysisContentViewBase : UIView
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *tipsLabel;
@property(nonatomic, strong) BDUGTokenShareAnalysisResultModel *insideModel;
@property(nonatomic, assign) NSInteger titleLineHeight;
@property(nonatomic, copy) void (^tipTapBlock)(void);
///失败回调

- (void)refreshContent:(BDUGTokenShareAnalysisResultModel *)resultModel;
- (void)refreshFrame;
@end
