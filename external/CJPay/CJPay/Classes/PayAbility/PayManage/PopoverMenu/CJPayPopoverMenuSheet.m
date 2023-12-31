//
//  CJPayPopoverMenuSheet.m
//  Pods
//
//  Created by 易培淮 on 2021/3/17.
//

#import "CJPayPopoverMenuSheet.h"
#import "CJPayPopoverMenuCell.h"
#import "CJPaySDKMacro.h"

@implementation CJPayPopoverMenuModel

+ (instancetype)actionWithTitle:(NSString *)title titleTextAlignment:(NSTextAlignment)titleTextAlignment block:(CJPayPopoverMenuModelBlock)block {
    CJPayPopoverMenuModel *model = [CJPayPopoverMenuModel new];
    model.title = title;
    model.block = block;
    model.titleTextAlignment = titleTextAlignment;
    return model;
}

@end

#pragma mark - CJPayPopoverMenuSheet

@interface CJPayPopoverMenuSheet () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *models;
@property (nonatomic, assign) NSInteger clickedButtonIndex;

@end

@implementation CJPayPopoverMenuSheet

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        _models = [NSMutableArray new];
        _clickedButtonIndex = NSNotFound;
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.alwaysBounceVertical = NO;
        self.tableView.tableFooterView = [UIView new];
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.tableView.backgroundView = [UIView new];
        self.tableView.showsVerticalScrollIndicator = NO;
        [self.tableView registerClass:[CJPayPopoverMenuCell class] forCellReuseIdentifier:NSStringFromClass([CJPayPopoverMenuCell class])];
    }

    return self;
}

#pragma mark - LifeCycle

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.preferredContentSize = CGSizeMake(self.width, self.tableView.contentSize.height);
}

#pragma mark - Public Method

- (void)addButtonWithModel:(CJPayPopoverMenuModel *)model
{
    [self.models addObject:model];
}

- (void)showFromView:(UIView *)view
              atRect:(CGRect)rect
      arrowDirection:(UIPopoverArrowDirection)direction {
    UIPopoverPresentationController *popover = [self popoverPresentationController];
    popover.delegate = self;
    popover.permittedArrowDirections = direction;
    popover.sourceView = view;
    popover.sourceRect = rect;
    popover.backgroundColor = self.tableView.backgroundColor;//popover小箭头颜色
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    self.clickedButtonIndex = buttonIndex;
   
    [self dismissViewControllerAnimated:animated completion:nil];

    if (buttonIndex >= 0 && buttonIndex < self.models.count) {
        CJPayPopoverMenuModel *model = self.models[buttonIndex];
        if (model.block != nil) {
            CJ_CALL_BLOCK(model.block,self, buttonIndex);
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayPopoverMenuCell *cell = (CJPayPopoverMenuCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CJPayPopoverMenuCell class])];
    CJPayPopoverMenuModel *action = self.models[indexPath.row];
    cell.textLabel.text = action.title;

    if (indexPath.row == self.models.count - 1) {
        [cell setSeparatorViewHidden:YES];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.cellHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissWithClickedButtonIndex:indexPath.row animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(CJPayPopoverMenuCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayPopoverMenuModel *action = self.models[indexPath.row];
    cell.textLabel.textAlignment = action.titleTextAlignment;
    cell.textLabel.font = self.titleFont;
    cell.layer.cornerRadius = self.cornerRadius;
}

#pragma mark - UIPopoverPresentationControllerDelegate

// 点击浮窗背景popover controller是否消失
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

// 浮窗消失时调用
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
}

@end

