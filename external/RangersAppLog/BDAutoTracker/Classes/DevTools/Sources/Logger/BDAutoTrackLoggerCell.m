//
//  BDAutoTrackLoggerCell.m
//  RangersAppLog
//
//  Created by bytedance on 7/4/22.
//

#import "BDAutoTrackLoggerCell.h"
#import "RangersLogManager.h"

@implementation BDAutoTrackLoggerCell {
    UILabel *timeLabel;
    UILabel *flagLabel;
    UILabel *moduleLabel;
    UILabel *contentLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initUI];
    }
    return self;
}

- (void)initUI
{
    timeLabel = [UILabel new];
    timeLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightRegular];
    timeLabel.textColor = [UIColor lightGrayColor];
    
    flagLabel = [UILabel new];
    flagLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightBold];
    flagLabel.textColor = [UIColor whiteColor];
    flagLabel.textAlignment = NSTextAlignmentCenter;
    
    flagLabel.layer.cornerRadius = 4.0f;
    flagLabel.clipsToBounds = YES;
    
    moduleLabel = [UILabel new];
    moduleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    
    contentLabel = [UILabel new];
    contentLabel.numberOfLines = 99;
    contentLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular];
    contentLabel.textColor = [UIColor darkGrayColor];
    contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [self.contentView addSubview:timeLabel];
    [self.contentView addSubview:flagLabel];
    [self.contentView addSubview:moduleLabel];
    [self.contentView addSubview:contentLabel];
    
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    moduleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    flagLabel.translatesAutoresizingMaskIntoConstraints = NO;
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[flag(68)]-[time]-[module]"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"time":timeLabel,
                                                                                       @"flag":flagLabel,
                                                                                       @"module":moduleLabel,
                                                                                       @"content":contentLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[content]-|"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"content":contentLabel}]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[time(18)]-[content]-|"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"time":timeLabel,
                                                                                       @"flag":flagLabel,
                                                                                       @"module":moduleLabel,
                                                                                       @"content":contentLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[module(time)]"
                                                                             options:0
                                                                             metrics:@{}
                                                                               views:@{@"time":timeLabel,
                                                                                       @"module":moduleLabel}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[flag(time)]"
                                                                                  options:0
                                                                                  metrics:@{}
                                                                                    views:@{@"time":timeLabel,
                                                                                            @"flag":flagLabel}]];
    
    
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (NSString *)formatTimestamp:(NSTimeInterval)ts
{
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    });
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

- (void)updateFlagLabelStyle
{
    switch (self.log.flag) {
        case VETLOG_FLAG_ERROR:
            flagLabel.text = @"ERROR";
            flagLabel.backgroundColor = [UIColor redColor];
            flagLabel.textColor = [UIColor whiteColor];
            break;
        case VETLOG_FLAG_WARN:
            flagLabel.text = @"WARN";
            flagLabel.backgroundColor = [UIColor orangeColor];
            flagLabel.textColor = [UIColor whiteColor];
            break;
        case VETLOG_FLAG_INFO:
            flagLabel.text = @"INFO";
            flagLabel.backgroundColor = [UIColor greenColor];
            flagLabel.textColor = [UIColor darkGrayColor];
            break;;
        default:
            flagLabel.text = @"DEBUG";
            flagLabel.backgroundColor = [UIColor greenColor];
            flagLabel.textColor = [UIColor darkGrayColor];
            break;
    }
}

- (void)update
{
    timeLabel.text = [[self class] formatTimestamp:self.log.timestamp];
    moduleLabel.text = self.log.module;
    contentLabel.text = self.log.message;
    [self updateFlagLabelStyle];
}

+ (CGFloat)estimateHeight:(RangersLogObject *)log
{
    NSDictionary* attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular]};
        
    
    CGRect rect = [log.message boundingRectWithSize:CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 16.0f), 999.0f)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attributes
                                         context:nil];
    
    return CGRectGetHeight(rect) + 32.0f + 18.0f;
}

@end
