//
//  BDXPageBaseView.h
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import "BDXPageBaseView.h"
#import "BDXCategoryIndicatorLineView.h"

@interface BDXPageIndicatorView : BDXPageBaseView

@property (nonatomic, strong, readonly) BDXCategoryIndicatorLineView *indicatorLineView;

- (void)hideIndicatorLine: (BOOL)hidden;

@end
