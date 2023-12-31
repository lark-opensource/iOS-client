//
//  BDAutoTrackSummary.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import "BDAutoTrackSummary.h"
#import "BDAutoTrackForm.h"
#import "BDAutoTrack+Private.h"

@interface BDAutoTrackSummary () {
    BDAutoTrackForm *form;
}

@end

@implementation BDAutoTrackSummary

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    form = [BDAutoTrackForm new];
    [form embedIn:self];
    
//    NSArray *elements = [self transformElements:self.target];
//    
//    form.groups = @[
//        [BDAutoTrackFormGroup groupWithTitle:self.title elements:elements]
//    ];
//    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    form.groups = self.groups;
}


@end
