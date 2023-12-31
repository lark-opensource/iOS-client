//
//  DownLabel.h
//  Pods
//
#import <UIKit/UIKit.h>

typedef enum {
    VerticalAlignmentTop = 0, //default
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,

} VerticalAlignment;


@interface BDCTAlignLabel : UILabel
{
   @private
    VerticalAlignment _verticalAlignment;
}

@property (nonatomic) VerticalAlignment verticalAlignment;

@end
