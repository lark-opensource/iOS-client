//
//  TTKitchenSearchHistoryView.h
//  TTKitchen
//
//  Created by zhanghuipei on 2021/6/9.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TTKitchenSearchHistoryView;

@protocol TTKitchenSearchHistoryViewDelegate <NSObject>

- (void)searchHistoryView:(TTKitchenSearchHistoryView *)historyView didClickHistoryButton:(NSString *)searchKey;

@end

@interface TTKitchenSearchHistoryView : UIView

@property (nonatomic, weak) id<TTKitchenSearchHistoryViewDelegate> delegate;

- (void)showInView:(UIView *)parent;

- (void)saveSearchKeyword:(NSString *)keyword;

- (void)removeSearchHistoryViewFromSuperview;

@end

NS_ASSUME_NONNULL_END
