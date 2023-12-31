//
//  ACCPopupTableViewController+Delegate.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/27.
//

#import "ACCPopupTableViewController.h"
#import "ACCPopupTableViewController+Delegate.h"

@implementation ACCPopupTableViewController(Delegate)

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell<ACCPopupTableViewCellProtocol> *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell respondsToSelector:@selector(onCellClicked)]) {
        [cell onCellClicked];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    if (indexPath.row < [self.dataManager countOfSelectedItems]) {
        id<ACCPopupTableViewDataItemProtocol> cellItem = [self.dataManager getItemAtIndex:indexPath];
        height = [cellItem.cellClass cellHeight];
    }
    return height;
}

@end
