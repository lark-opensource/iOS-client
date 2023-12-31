//
//  BDAutoTrackDevEventCell.m
//  RangersAppLog
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDevEventCell.h"

@implementation BDAutoTrackDevEventCell {
    UILabel *typeLabel;
    UILabel *statusLabel1;
    UILabel *statusLabel2;
    UILabel *statusLabel3;
    UILabel *timeLabel;
    UILabel *nameLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    typeLabel = [UILabel new];
    typeLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    typeLabel.textAlignment = NSTextAlignmentCenter;
    typeLabel.layer.cornerRadius = 4.0f;
    typeLabel.layer.borderColor = [[UIColor greenColor] CGColor];
    typeLabel.layer.borderWidth = 1.0f;
    typeLabel.clipsToBounds = YES;
    
    timeLabel = [UILabel new];
    timeLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    timeLabel.textColor = [UIColor lightGrayColor];
    
    statusLabel1 = [self createStatusLabel];
    statusLabel2 = [self createStatusLabel];
    statusLabel3 = [self createStatusLabel];
    
    nameLabel = [UILabel new];
    nameLabel.numberOfLines = 99;
    nameLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightMedium];
    nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [self.contentView addSubview:typeLabel];
    [self.contentView addSubview:timeLabel];
    [self.contentView addSubview:statusLabel1];
    [self.contentView addSubview:statusLabel2];
    [self.contentView addSubview:statusLabel3];
    [self.contentView addSubview:nameLabel];
    
    typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    statusLabel1.translatesAutoresizingMaskIntoConstraints = NO;
    statusLabel2.translatesAutoresizingMaskIntoConstraints = NO;
    statusLabel3.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[time]-[status1(48)]-[status2(48)]-[status3(48)]"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"status1":statusLabel1,
                                                                                       @"status2":statusLabel2,
                                                                                       @"status3":statusLabel3,
                                                                                       @"time":timeLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[type(70)]-[name]-|"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"type":typeLabel,
                                                                                       @"name":nameLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[time(18)]-[name]-|"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"time":timeLabel,
                                                                                       @"name":nameLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[time(18)]-[type(22)]"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"time":timeLabel,
                                                                                       @"type":typeLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[status1(time)]"
                                                                                  options:0
                                                                                  metrics:@{}
                                                                                    views:@{@"time":timeLabel,
                                                                                            @"status1":statusLabel1}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[status2(time)]"
                                                                                  options:0
                                                                                  metrics:@{}
                                                                                    views:@{@"time":timeLabel,
                                                                                            @"status2":statusLabel2}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[status3(time)]"
                                                                                  options:0
                                                                                  metrics:@{}
                                                                                    views:@{@"time":timeLabel,
                                                                                            @"status3":statusLabel3}]];
}

- (UILabel *)createStatusLabel {
    UILabel *statusLabel = [UILabel new];
    statusLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.layer.cornerRadius = 4.0f;
    statusLabel.clipsToBounds = YES;
    return statusLabel;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)update {
    typeLabel.text = self.event.typeStr;
    timeLabel.text = self.event.timeStr;
    nameLabel.text = self.event.name;
    if (!nameLabel.text) {
        nameLabel.text = @" ";
    }
    
    [self updateStatusLabel:statusLabel1 index:0];
    [self updateStatusLabel:statusLabel2 index:1];
    [self updateStatusLabel:statusLabel3 index:2];
    
//    NSLog(@"type >>> %ld", self.event.type);
//    NSLog(@"time >>> %@", self.event.timeStr);
}

- (void)updateStatusLabel:(UILabel *)statusLabel index:(NSInteger) index {
    NSArray<NSString *> *strList = self.event.statusStrList;
    statusLabel.text = nil;
    statusLabel.backgroundColor = [UIColor whiteColor];
    if (strList.count > index) {
        BDAutoTrackEventStatus status = [[self.event.statusList objectAtIndex:index] intValue];
        statusLabel.text = [strList objectAtIndex:index];
        if (status == BDAutoTrackEventStatusSaveFailed) {
            statusLabel.textColor = [UIColor whiteColor];
            statusLabel.backgroundColor = [UIColor redColor];
        } else {
            statusLabel.textColor = [UIColor darkGrayColor];
            statusLabel.backgroundColor = [UIColor greenColor];
        }
    }
}

+ (CGFloat)estimateHeight:(BDAutoTrackDevEventData *)event {
    NSDictionary* attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular]};
        
    
    CGRect rect = [event.name boundingRectWithSize:CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 16.0f), 999.0f)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attributes
                                         context:nil];
    
    return CGRectGetHeight(rect) + 32.0f + 18.0f;
}

@end
