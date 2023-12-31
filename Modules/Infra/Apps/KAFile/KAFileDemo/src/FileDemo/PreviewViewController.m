//
//  SVGPreviewViewController.m
//  KAFileDemo
//
//  Created by Supeng on 2021/12/2.
//

#import "PreviewViewController.h"
@import PDFKit;

@interface PreviewViewController () {
    PDFView* _pdfView;
}
@property (nonatomic, copy) NSString* filePath;
@end

@implementation PreviewViewController

-(instancetype)init {
    return [self initWithFilePath:@""];
}

-(instancetype)initWithFilePath: (NSString*)filePath {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _filePath = filePath;
        return self;
    }
    return nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self view] setBackgroundColor:[UIColor whiteColor]];

    NSURL *pdfUrl = [NSURL fileURLWithPath:self.filePath];
    PDFDocument *docunment = [[PDFDocument alloc] initWithURL:pdfUrl];

    _pdfView = [[PDFView alloc] initWithFrame:self.view.bounds];
    _pdfView.document = docunment;
    _pdfView.autoScales = YES;
    _pdfView.userInteractionEnabled = YES;
    _pdfView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_pdfView];
}

- (void)viewWillAppear:(BOOL)animated {
    _pdfView.frame = [[self view] bounds];
}

@end
