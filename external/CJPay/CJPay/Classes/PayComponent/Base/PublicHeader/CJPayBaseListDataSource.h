//
//  CJPayBaseListDataSource.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseListDataSource : NSObject

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<CJPayBaseListViewModel *> *> *sectionsDataDic;

- (CJPayBaseListViewModel *)viewModelAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
