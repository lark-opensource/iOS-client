//
//  BDXPageListView.m
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import "BDXPageListView.h"

@implementation BDXPageListView

#pragma mark - BDXCategoryListContentViewDelegate

- (UIView *)listView {
    if ([self.delegate respondsToSelector:@selector(listView)]) {
        return [self.delegate listView];
    }
    return self;
}

- (UIScrollView *)listScrollView {
    if ([self.delegate respondsToSelector:@selector(listScrollView)]) {
        return [self.delegate listScrollView];
    }
    return nil;
}

- (void)listViewDidScrollCallback:(void (^)(UIScrollView *))callback {
    if ([self.delegate respondsToSelector:@selector(listViewDidScrollCallback:)]) {
        [self.delegate listViewDidScrollCallback:callback];
    }
}

@end
