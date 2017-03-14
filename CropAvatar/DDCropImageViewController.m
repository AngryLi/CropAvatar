//
//  DDCropImageViewController.m
//  CropAvatar
//
//  Created by 李亚洲 on 2017/3/14.
//  Copyright © 2017年 李亚洲. All rights reserved.
//

#import "DDCropImageViewController.h"

@implementation UIImageView(CropAvatar)

- (CGSize)sizeFit:(CGSize)size
{
    CGSize fitSize = CGSizeZero;
    CGFloat imageRatio = self.bounds.size.width / self.bounds.size.height;
    CGFloat containerRatio = size.width / size.height;
    
    if (imageRatio > containerRatio)
    {
        fitSize.width = size.width;
        fitSize.height = fitSize.width / self.bounds.size.width * self.bounds.size.height;
    }
    else if (imageRatio == containerRatio)
    {
        fitSize = size;
    }
    else
    {
        fitSize.height = size.height;
        fitSize.width = fitSize.height / self.bounds.size.height * self.bounds.size.width;
    }
    return fitSize;
}

@end

@interface DDCropImageViewController () <UIScrollViewDelegate>
@property (strong, nonatomic, readwrite) UIImageView *imageView;
@property (strong, nonatomic, readwrite) UIScrollView *scrollView;

@property (assign, nonatomic, readwrite) CGRect cropRect;
@end

@implementation DDCropImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBarHidden = YES;
    
    [self _buildUI];
}

- (void)_buildUI
{
    // bottom
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame) - 60, self.view.bounds.size.width, 60)];
    bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomView];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:@"cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(action_cancel) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setTitle:@"done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(action_done) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    cancelButton.frame = CGRectMake(0, 0, CGRectGetWidth(bottomView.bounds) * 0.5, bottomView.bounds.size.height);
    doneButton.frame = CGRectMake(CGRectGetWidth(bottomView.bounds) * 0.5, 0, CGRectGetWidth(bottomView.bounds) * 0.5, bottomView.bounds.size.height);
    
    [bottomView addSubview:cancelButton];
    [bottomView addSubview:doneButton];
    
    // UIImageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.sourceImage];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.autoresizingMask =UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;
    UIScrollView *containScrollerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - bottomView.bounds.size.height)];
    containScrollerView.showsVerticalScrollIndicator = NO;
    containScrollerView.showsHorizontalScrollIndicator = NO;
    containScrollerView.scrollsToTop = NO;
    containScrollerView.multipleTouchEnabled = YES;
    containScrollerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containScrollerView.decelerationRate = UIScrollViewDecelerationRateFast;
    containScrollerView.delaysContentTouches = NO;
    containScrollerView.canCancelContentTouches = YES;
    containScrollerView.alwaysBounceVertical = NO;
    self.scrollView = containScrollerView;
    
    CGSize imageViewSize = [imageView sizeFit:containScrollerView.bounds.size];
    
    containScrollerView.contentSize = imageViewSize;
    containScrollerView.alwaysBounceVertical = imageViewSize.height < containScrollerView.bounds.size.height;
    containScrollerView.delegate = self;
    containScrollerView.maximumZoomScale = 5;
    containScrollerView.minimumZoomScale = 1;
    
    imageView.frame = CGRectMake(0, containScrollerView.center.y - imageViewSize.height * 0.5, imageViewSize.width, imageViewSize.height);
    
    [containScrollerView addSubview:imageView];
    [self.view addSubview:containScrollerView];
    
    // 覆盖浮层
    CAShapeLayer *overLayer = [[CAShapeLayer alloc] init];
    overLayer.frame = containScrollerView.frame;
    overLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
    overLayer.fillRule = kCAFillRuleEvenOdd;
    
    self.cropRect = CGRectMake( 0, (overLayer.frame.size.height - overLayer.frame.size.width) * 0.5, overLayer.frame.size.width, overLayer.frame.size.width);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, overLayer.frame);
    CGPathAddEllipseInRect(path, NULL, self.cropRect);
//    CGPathAddRect(path, NULL, self.cropRect);
    overLayer.path = path;
    
    [self.view.layer addSublayer:overLayer];
}

// MARK: action

- (void)action_done
{
    UIImage *image = [self cropImageView:self.imageView toRect:self.cropRect zoomScale:self.scrollView.zoomScale containerView:self.view];
    
    image = [self circularClipImage:image];
    if (_delegate) {
        [_delegate cropImageViewController:self didFinish:image];
    }
}

- (void)action_cancel
{
    if (_delegate) {
        [_delegate cropImageViewControllerCanceled:self];
    }
}

// MARK: UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollView.contentInset = UIEdgeInsetsZero;
    scrollView.contentSize = _imageView.frame.size;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self refreshScrollViewContentSize];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self refreshImageContainerViewCenter];
}

- (void)refreshScrollViewContentSize
{
    NSLog(@"%s", __func__);
    CGFloat contentWidthAdd = self.scrollView.bounds.size.width - CGRectGetMaxX(_cropRect);
    CGFloat contentHeightAdd = (MIN(_imageView.frame.size.height, self.scrollView.bounds.size.height) - self.cropRect.size.height) * 0.5;
    CGFloat newSizeW = self.scrollView.contentSize.width + contentWidthAdd;
    CGFloat newSizeH = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height) + contentHeightAdd;
    _scrollView.contentSize = CGSizeMake(newSizeW, newSizeH);
    _scrollView.alwaysBounceVertical = YES;
    if (contentHeightAdd > 0) {
        _scrollView.contentInset = UIEdgeInsetsMake(contentHeightAdd, _cropRect.origin.x, 0, 0);
    } else {
        _scrollView.contentInset = UIEdgeInsetsZero;
    }
}

- (void)refreshImageContainerViewCenter
{
    NSLog(@"%s", __func__);
    CGFloat offsetX = (_scrollView.bounds.size.width > _scrollView.contentSize.width) ? ((_scrollView.bounds.size.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.bounds.size.height > _scrollView.contentSize.height) ? ((_scrollView.bounds.size.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"%@", NSStringFromCGSize(scrollView.contentSize));
//    NSLog(@"%@", NSStringFromCGSize(self.imageView.frame.size));
}

/// 获得裁剪后的图片
- (UIImage *)cropImageView:(UIImageView *)imageView toRect:(CGRect)rect zoomScale:(double)zoomScale containerView:(UIView *)containerView {
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 平移的处理
    CGRect imageViewRect = [imageView convertRect:imageView.bounds toView:containerView];
    CGPoint point = CGPointMake(imageViewRect.origin.x + imageViewRect.size.width / 2, imageViewRect.origin.y + imageViewRect.size.height / 2);
    CGFloat xMargin = containerView.bounds.size.width - CGRectGetMaxX(rect) - rect.origin.x;
    CGPoint zeroPoint = CGPointMake((CGRectGetWidth(containerView.frame) - xMargin) / 2, containerView.center.y);
    CGPoint translation = CGPointMake(point.x - zeroPoint.x, point.y - zeroPoint.y);
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
    // 缩放的处理
    transform = CGAffineTransformScale(transform, zoomScale, zoomScale);
    
    CGImageRef imageRef = [self newTransformedImage:transform
                                        sourceImage:imageView.image.CGImage
                                         sourceSize:imageView.image.size
                                        outputWidth:rect.size.width * [UIScreen mainScreen].scale
                                           cropSize:rect.size
                                      imageViewSize:imageView.frame.size];
    UIImage *cropedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropedImage;
}

- (CGImageRef)newTransformedImage:(CGAffineTransform)transform sourceImage:(CGImageRef)sourceImage sourceSize:(CGSize)sourceSize  outputWidth:(CGFloat)outputWidth cropSize:(CGSize)cropSize imageViewSize:(CGSize)imageViewSize {
    CGImageRef source = [self newScaledImage:sourceImage toSize:sourceSize];
    
    CGFloat aspect = cropSize.height/cropSize.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL, outputSize.width, outputSize.height, CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), CGImageGetBitmapInfo(source));
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width / cropSize.width, outputSize.height / cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width/2.0, cropSize.height / 2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2, -imageViewSize.height/2.0, imageViewSize.width, imageViewSize.height), source);
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGImageRelease(source);
    return resultRef;
}

- (CGImageRef)newScaledImage:(CGImageRef)source toSize:(CGSize)size {
    CGSize srcSize = size;
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextTranslateCTM(context, size.width/2, size.height/2);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2, -srcSize.height/2, srcSize.width, srcSize.height), source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

/// 获取圆形图片
- (UIImage *)circularClipImage:(UIImage *)image {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextAddEllipseInRect(ctx, rect);
    CGContextClip(ctx);
    
    [image drawInRect:rect];
    UIImage *circleImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return circleImage;
}

@end