//
//  BDXLynxSwiperCellLayout.m
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import "BDXLynxSwiperCellLayout.h"

typedef NS_ENUM(NSUInteger, BDXLynxSwiperTransLayoutItemDirection) {
    BDXLynxSwiperTransLayoutItemLeft,
    BDXLynxSwiperTransLayoutItemCenter,
    BDXLynxSwiperTransLayoutItemRight,
    BDPLynxSwiperTransLayoutItemTop,
    BDPLynxSwiperTransLayoutItemBottom,
};

@interface BDXLynxSwiperViewLayout ()

@property (nonatomic, weak) UIView *pageView;

@end

@interface BDXLynxSwiperTransformLayout () {
    struct {
        unsigned int applyTransformToAttributes   :1;
        unsigned int initializeTransformAttributes   :1;
    }_delegateFlags;
}

@property (nonatomic, assign) BOOL applyTransformToAttributesDelegate;

@end

@implementation BDXLynxSwiperTransformLayout

- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

#pragma mark - getter setter

- (void)setDelegate:(id<BDXLynxSwiperTransformLayoutDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:applyTransformToAttributes:)];
}

- (void)setLayout:(BDXLynxSwiperViewLayout *)layout {
    _layout = layout;
    _layout.pageView = self.collectionView;
    self.itemSize = _layout.itemSize;
    self.minimumInteritemSpacing = _layout.itemSpacing;
    self.minimumLineSpacing = _layout.itemSpacing;
    if (layout.vertical) {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
    } else {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
}

- (CGSize)itemSize {
    if (!_layout) {
        return [super itemSize];
    }
    return _layout.itemSize;
}

- (CGFloat)minimumLineSpacing {
    if (!_layout) {
        return [super minimumLineSpacing];
    }
    return _layout.itemSpacing;
}

- (CGFloat)minimumInteritemSpacing {
    if (!_layout) {
        return [super minimumInteritemSpacing];
    }
    return _layout.itemSpacing;
}

- (BDXLynxSwiperTransLayoutItemDirection)directionWithCenter:(CGFloat)center size:(CGFloat)size{
  BDXLynxSwiperTransLayoutItemDirection direction = self.layout.vertical ? BDPLynxSwiperTransLayoutItemBottom :  BDXLynxSwiperTransLayoutItemRight;
    CGFloat contentCenter;
    if (self.layout.vertical) {
        contentCenter = self.collectionView.contentOffset.y + size / 2 + self.layout.sectionInset.top;
    } else {
        contentCenter = self.collectionView.contentOffset.x + size / 2 + self.layout.sectionInset.left;
    }
    if (ABS(center - contentCenter) < 0.5) {
        direction = BDXLynxSwiperTransLayoutItemCenter;
    }else if (center - contentCenter < 0) {
        if (self.layout.vertical) {
            direction = BDPLynxSwiperTransLayoutItemTop;
        } else {
          direction = BDXLynxSwiperTransLayoutItemLeft;
        }
    }
    return direction;
}

#pragma mark - layout

- (UIUserInterfaceLayoutDirection)developmentLayoutDirection {
    return self.layout.isRTL ? UIUserInterfaceLayoutDirectionRightToLeft : UIUserInterfaceLayoutDirectionLeftToRight;
}

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return YES;
}

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return _layout.layoutType == BDXLynxSwiperTransformLayoutNormal ? [super shouldInvalidateLayoutForBoundsChange:newBounds] : YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (_delegateFlags.applyTransformToAttributes || _layout.layoutType != BDXLynxSwiperTransformLayoutNormal) {
        
        NSArray *attributesArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
            if (_delegateFlags.applyTransformToAttributes) {
                [_delegate pagerViewTransformLayout:self applyTransformToAttributes:attributes];
            }else {
                [self applyTransformToAttributes:attributes layoutType:_layout.layoutType];
            }
        }
        return attributesArray;
    }
    return [super layoutAttributesForElementsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate pagerViewTransformLayout:self initializeTransformAttributes:attributes];
    }else if(_layout.layoutType != BDXLynxSwiperTransformLayoutNormal){
        [self initializeTransformAttributes:attributes layoutType:_layout.layoutType];
    }
    return attributes;
}

#pragma mark - transform

- (void)initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(BDXLynxSwiperTransformLayoutType)layoutType {
    switch (layoutType) {
        case BDXLynxSwiperTransformLayoutLinear:
        case BDXLynxSwiperTransformLayoutCarry:
            [self applyLinearTransformToAttributes:attributes
                                            scaleX:_layout.minXScale
                                            scaleY:_layout.minYScale
                                             alpha:_layout.minimumAlpha];
            break;
        case BDXLynxSwiperTransformLayoutCoverflow:
        {
            [self applyCoverflowTransformToAttributes:attributes angle:_layout.maximumAngle alpha:_layout.minimumAlpha];
            break;
        }
        default:
            break;
    }
}

- (void)applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(BDXLynxSwiperTransformLayoutType)layoutType
{
    switch (layoutType) {
        case BDXLynxSwiperTransformLayoutLinear:
        case BDXLynxSwiperTransformLayoutCarry:
            [self applyLinearTransformToAttributes:attributes];
            break;
        case BDXLynxSwiperTransformLayoutCoverflow:
            [self applyCoverflowTransformToAttributes:attributes];
            break;
        default:
            break;
    }
}

#pragma mark - LinearTransform

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewSize = self.layout.vertical ? self.collectionView.frame.size.height : self.collectionView.frame.size.width;
    if (collectionViewSize <= 0) {
        return;
    }
    CGFloat centet = self.layout.vertical ? self.collectionView.contentOffset.y : self.collectionView.contentOffset.x + collectionViewSize/2 - (self.layout.vertical ? (self.layout.sectionInset.bottom - self.layout.sectionInset.top) : (self.layout.sectionInset.right - self.layout.sectionInset.left)) / 2;
    CGFloat delta = ABS((self.layout.vertical ? attributes.center.y : attributes.center.x) - centet);
//    CGFloat scale = MAX(1 - delta/collectionViewSize*_layout.rateOfChange, _layout.minimumScale);
    CGFloat alpha = MAX(1 - delta/collectionViewSize, _layout.minimumAlpha);
    
    CGRect visibleRect = CGRectZero;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    CGFloat distance = (self.layout.vertical ? CGRectGetMidY(visibleRect) : CGRectGetMidX(visibleRect)) - (self.layout.vertical ? attributes.center.y : attributes.center.x) - (self.layout.vertical ? (self.layout.sectionInset.bottom - self.layout.sectionInset.top) : (self.layout.sectionInset.right - self.layout.sectionInset.left)) / 2;
    CGFloat normalizedDistance = MIN(fabs(distance / (self.layout.vertical ? attributes.size.height : attributes.size.width)), 1);
    
    CGFloat zoomX = (normalizedDistance*(self.layout.minXScale - self.layout.maxXScale) + self.layout.maxXScale);
    CGFloat zoomY = (normalizedDistance*(self.layout.minYScale - self.layout.maxYScale) + self.layout.maxYScale);

    CGFloat translateY = 0;
    CGFloat translateX = 0;
  if (self.layout.normTranslationFactor > 0. && self.layout.vertical ? (self.layout.maxYScale > self.layout.minYScale) : (self.layout.maxXScale > self.layout.minXScale)) {
      
    CGFloat interval = self.layout.vertical ? (attributes.frame.size.height * (1- MAX(zoomY, self.layout.minYScale))) : (attributes.frame.size.width * (1- MAX(zoomX, self.layout.minXScale)));
      CGFloat normFactor = self.layout.normTranslationFactor;
    
    CGFloat adjust = 0;
    CGFloat adjustNormalizedDistance = fabs(distance / (self.layout.vertical ? attributes.size.height : attributes.size.width));
    if (adjustNormalizedDistance > 1) {
      adjustNormalizedDistance = adjustNormalizedDistance - 1;
      adjust = (adjustNormalizedDistance*(self.layout.minXScale - self.layout.maxXScale) + self.layout.maxXScale);
      interval =  interval + (self.layout.vertical ? (attributes.frame.size.height * (1 - adjust)) : (attributes.frame.size.width * (1 - adjust))) * 2;
    }

      if (distance > 0) {
        if (self.layout.vertical) {
          translateY = 0.5f * normFactor * interval;
        } else {
          translateX = 0.5f * normFactor * interval;
        }
      } else {
        if (self.layout.vertical) {
          translateY = -0.5f * normFactor * interval;
        } else {
          translateX = -0.5f * normFactor * interval;
        }
      }
      [self applyLinearTransformToAttributes:attributes
                                  translateX:translateX
                                  translateY:translateY
                                      scaleX:MAX(zoomX, self.layout.minXScale)
                                      scaleY:MAX(zoomY, self.layout.minYScale)
                                       alpha:alpha];
    } else {
      [self applyLinearTransformToAttributes:attributes
                                      scaleX:MAX(zoomX, self.layout.minXScale)
                                      scaleY:MAX(zoomY, self.layout.minYScale)
                                       alpha:alpha];
    }
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY alpha:(CGFloat)alpha {
    CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, scaleY);
    attributes.transform = transform;
    attributes.alpha = alpha;
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes
                              translateX:(CGFloat)translateX
                              translateY:(CGFloat)translateY
                                  scaleX:(CGFloat)scaleX
                                  scaleY:(CGFloat)scaleY
                                   alpha:(CGFloat)alpha {
    CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, scaleY);
    transform = CGAffineTransformTranslate(transform, translateX / scaleX, translateY / scaleY);
    attributes.transform = transform;
    attributes.alpha = alpha;
}

#pragma mark - CoverflowTransform

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes{
    CGFloat collectionViewSize = self.layout.vertical ? self.collectionView.frame.size.height : self.collectionView.frame.size.width;
    if (collectionViewSize <= 0) {
        return;
    }
  CGFloat centet = (self.layout.vertical ? self.collectionView.contentOffset.y : self.collectionView.contentOffset.x) + collectionViewSize/2 - (self.layout.vertical ? (self.layout.sectionInset.bottom - self.layout.sectionInset.top) : (self.layout.sectionInset.right - self.layout.sectionInset.left)) / 2;
    CGFloat delta = ABS((self.layout.vertical ? attributes.center.y : attributes.center.x) - centet);
    CGFloat angle = MIN(delta/collectionViewSize*(1-_layout.rateOfChange), _layout.maximumAngle);
    CGFloat alpha = MAX(1 - delta/collectionViewSize, _layout.minimumAlpha);

    [self applyCoverflowTransformToAttributes:attributes angle:angle alpha:alpha];
}

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes angle:(CGFloat)angle alpha:(CGFloat)alpha {
  BDXLynxSwiperTransLayoutItemDirection direction = self.layout.vertical ? [self directionWithCenter:attributes.center.y size:attributes.frame.size.height] : [self directionWithCenter:attributes.center.x size:attributes.frame.size.width];
    CATransform3D transform3D = CATransform3DIdentity;
    transform3D.m34 = -0.002;
    CGFloat translate = 0;
  
    switch (direction) {
        case BDXLynxSwiperTransLayoutItemLeft:
            translate = (1-cos(angle*1.2*M_PI))*attributes.size.width;
            break;
        case BDXLynxSwiperTransLayoutItemRight:
            translate = -(1-cos(angle*1.2*M_PI))*attributes.size.width;
            angle = -angle;
            break;
        case BDPLynxSwiperTransLayoutItemTop:
            translate = (1 - cos(angle * 1.2 * M_PI)) * attributes.size.height;
            angle = -angle;
            break;
        case BDPLynxSwiperTransLayoutItemBottom:
            translate = - ( 1 - cos(angle * 1.2 * M_PI)) * attributes.size.height;
            break;
        default:
            // center
            angle = 0;
            alpha = 1;
            break;
    }

    if (self.layout.vertical) {
        transform3D = CATransform3DRotate(transform3D, M_PI*angle, 1, 0, 0);
    } else {
        transform3D = CATransform3DRotate(transform3D, M_PI*angle, 0, 1, 0);
    }
    
    if (_layout.adjustSpacingWhenScroling) {
        if (self.layout.vertical) {
            transform3D = CATransform3DTranslate(transform3D, 0, translate, 0);
        } else {
            transform3D = CATransform3DTranslate(transform3D, translate, 0, 0);
        }
    }
    if (_layout.layoutType != BDXLynxSwiperTransformLayoutFlatCoverflow) {
        attributes.transform3D = transform3D;
    }
    attributes.alpha = alpha;

}

@end


@implementation BDXLynxSwiperViewLayout

- (instancetype)init {
    if (self = [super init]) {
        _itemVerticalCenter = YES;
        _minimumScale = 0.8;
        _minimumAlpha = 1.0;
        _maximumAngle = 0.2;
        _rateOfChange = 0.4;
        _adjustSpacingWhenScroling = YES;
    }
    return self;
}

#pragma mark - getter

// UIEdgeInsets insets = {top, left, bottom, right};
- (UIEdgeInsets)onlyOneSectionInset {
    if (self.vertical) {
        CGFloat topSpace = _pageView && !self.isInfiniteLoop && _itemVerticalCenter ? (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2 : _sectionInset.top;
        CGFloat bottomSpace = _pageView && !self.isInfiniteLoop && _itemVerticalCenter ? (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2 : _sectionInset.bottom;
        if (_itemHorizontalCenter) {
            CGFloat horizonSpace = (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2;
            return UIEdgeInsetsMake(topSpace, horizonSpace, bottomSpace, horizonSpace);
        }
        return UIEdgeInsetsMake(topSpace, 0, bottomSpace, 0);
    } else {
        CGFloat leftSpace = _pageView && !self.isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.left;
        CGFloat rightSpace = _pageView && !self.isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.right;
        if (self.layoutType == BDXLynxSwiperTransformLayoutMultiplePages) {
            leftSpace = self.startMargin;
            rightSpace = self.endMargin;
        }
        if (_itemVerticalCenter) {
            CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
            return UIEdgeInsetsMake(verticalSpace, leftSpace, verticalSpace, rightSpace);
        }
        return UIEdgeInsetsMake(_sectionInset.top, leftSpace, _sectionInset.bottom, rightSpace);
    }
}

- (UIEdgeInsets)firstSectionInset {
    if (self.vertical) {
        if (_itemHorizontalCenter) {
            CGFloat horizonSpace = (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2;
            return UIEdgeInsetsMake(_sectionInset.top, horizonSpace, _itemSpacing, horizonSpace);
        }
        return UIEdgeInsetsMake(_sectionInset.top, 0, _itemSpacing, 0);
    } else {
        if (_itemVerticalCenter) {
            CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
            return UIEdgeInsetsMake(verticalSpace, _sectionInset.left, verticalSpace, _itemSpacing);
        }
        return UIEdgeInsetsMake(0, _sectionInset.left, 0, _itemSpacing);
    }
}

- (UIEdgeInsets)middleSectionInset {
    if (self.vertical) {
        if (_itemHorizontalCenter) {
            CGFloat horizonSpace = (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2;
            return UIEdgeInsetsMake(0, horizonSpace, _itemSpacing, horizonSpace);
        }
        return UIEdgeInsetsMake(0, 0, _itemSpacing, 0);
    } else {
        if (_itemVerticalCenter) {
            CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
            return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _itemSpacing);
        }
        return UIEdgeInsetsMake(0, 0, 0, _itemSpacing);
    }
}


- (UIEdgeInsets)lastSectionInset {
    if (self.vertical) {
        if (_itemHorizontalCenter) {
            CGFloat horizonSpace = (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2;
            return UIEdgeInsetsMake(0, horizonSpace, _sectionInset.bottom, horizonSpace);
        }
        return UIEdgeInsetsMake(0, 0, _sectionInset.bottom, 0);
    } else {
        if (_itemVerticalCenter) {
            CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
            return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _sectionInset.right);
        }
        return UIEdgeInsetsMake(0, 0, 0, _sectionInset.right);
    }
}

@end

@implementation BDXLynxSwiperTransformLayoutNonFlip

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return NO;
}

@end
