//
//  ACCPopupTableViewController+DataSource.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/27.
//

#import "ACCPopupTableViewController+DataSource.h"
#import "ACCPopupTableViewController.h"
#import "ACCPopupTableViewController+Delegate.h"

@implementation ACCPopupTableViewController(DataSource)

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataManager countOfSelectedItems];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<ACCPopupTableViewDataItemProtocol> cellItem = [self.dataManager getItemAtIndex:indexPath];
    UITableViewCell<ACCPopupTableViewCellProtocol> *cell = [[(Class)cellItem.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[cellItem.class description]];
    
    if ([cell respondsToSelector:@selector(delegate)]) {
        cell.delegate = self;
    }
    [cell updateWithItem:cellItem];
    return cell;
}

@end
