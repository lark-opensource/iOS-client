//
//  FaceLiveDebugViewController.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/5/5.
//

#import "FaceLiveDebugViewController.h"


@interface FaceLiveDebugViewController ()

@end


@implementation FaceLiveDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    return;
}

@end
