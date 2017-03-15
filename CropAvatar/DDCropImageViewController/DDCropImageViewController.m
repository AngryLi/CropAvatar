//
//  DDCropImageViewController.m
//  CropAvatar
//
//  Created by 李亚洲 on 2017/3/14.
//  Copyright © 2017年 李亚洲. All rights reserved.
//

#import "DDCropImageViewController.h"

@interface DDCropImageViewController () <UIScrollViewDelegate>
@property (strong, nonatomic, readwrite) UIView *bottomView;
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
    
    if (self.sourceImage == nil)
    {
        if (_delegate)
        {
            NSError *error = [NSError errorWithDomain:@"com.dada.cropImage" code:-1 userInfo:@{@"reason":@"原始图像不能为空"}];
            [_delegate cropImageViewController:self occurError:error];
        }
    }
    else
    {
        [self _buildUI];
        [self _renderImage];
    }
}

- (void)_renderBottomView
{
    // bottom
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame) - 60, self.view.bounds.size.width, 60)];
    bottomView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bottomView];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(action_cancel) forControlEvents:UIControlEventTouchUpInside];
//    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setTitle:@"确定" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(action_done) forControlEvents:UIControlEventTouchUpInside];
//    [doneButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    cancelButton.frame = CGRectMake(0, 0, CGRectGetWidth(bottomView.bounds) * 0.5, bottomView.bounds.size.height);
    doneButton.frame = CGRectMake(CGRectGetWidth(bottomView.bounds) * 0.5, 0, CGRectGetWidth(bottomView.bounds) * 0.5, bottomView.bounds.size.height);
    
    [bottomView addSubview:cancelButton];
    [bottomView addSubview:doneButton];
    self.bottomView = bottomView;
}

- (void)_renderScrollView
{
    // UIImageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.sourceImage];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.autoresizingMask =UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight;
    
    // UIScrollView
    UIScrollView *containScrollerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.bottomView.bounds.size.height)];
    containScrollerView.showsVerticalScrollIndicator = NO;
    containScrollerView.showsHorizontalScrollIndicator = NO;
    containScrollerView.scrollsToTop = NO;
    containScrollerView.multipleTouchEnabled = YES;
    containScrollerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containScrollerView.decelerationRate = UIScrollViewDecelerationRateFast;
    containScrollerView.delaysContentTouches = NO;
    containScrollerView.canCancelContentTouches = YES;
    containScrollerView.alwaysBounceVertical = NO;
    containScrollerView.delegate = self;
    containScrollerView.maximumZoomScale = 2.5;
    containScrollerView.minimumZoomScale = 1;
    
    // addSubview
    [containScrollerView addSubview:imageView];
    [self.view addSubview:containScrollerView];
    
    // 赋值
    self.imageView = imageView;
    self.scrollView = containScrollerView;
}

- (void)_renderOverLayer
{
    // 覆盖浮层
    CAShapeLayer *overLayer = [[CAShapeLayer alloc] init];
    overLayer.frame = self.scrollView.frame;
    overLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    overLayer.fillRule = kCAFillRuleEvenOdd;
    
    self.cropRect = CGRectMake( 0, (overLayer.frame.size.height - overLayer.frame.size.width) * 0.5, overLayer.frame.size.width, overLayer.frame.size.width);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, overLayer.frame);
    if (self.needRound) {
        CGPathAddEllipseInRect(path, NULL, self.cropRect);
    } else {
        CGPathAddRect(path, NULL, self.cropRect);
    }
    overLayer.path = path;
    
    [self.view.layer addSublayer:overLayer];
}

- (void)_buildUI
{
    [self _renderBottomView];
    
    [self _renderScrollView];
    
    [self _renderOverLayer];
}

- (void)_renderImage
{
    CGSize size = self.scrollView.bounds.size;
    CGSize imageSize = self.sourceImage.size;
    CGSize fitSize = CGSizeZero;
    CGFloat imageRatio = imageSize.width / imageSize.height;
//    CGFloat containerRatio = size.width / size.height;
    fitSize.width = size.width;
    fitSize.height = fitSize.width / imageRatio;
    if (fitSize.height < CGRectGetHeight(self.cropRect))
    {
        fitSize.height = CGRectGetHeight(self.cropRect);
        fitSize.width = fitSize.height * imageRatio;
    }
    
    self.imageView.image = self.sourceImage;
    self.imageView.frame = CGRectMake(0, size.height * 0.5 - fitSize.height * 0.5, fitSize.width, fitSize.height);
    self.scrollView.contentSize = fitSize;
    
    [self refreshImageContainerViewCenter];
    [self refreshScrollViewContentSize];
}

// not use
- (CGSize)_imageSize:(CGSize)imageSize fitInSize:(CGSize)containerSize
{
    CGSize fitSize = CGSizeZero;
    CGFloat imageRatio = imageSize.width / imageSize.height;
    CGFloat containerRatio = containerSize.width / containerSize.height;
    
    if (imageRatio > containerRatio)
    {
        fitSize.width = containerSize.width;
        fitSize.height = fitSize.width / imageRatio;
    }
    else if (imageRatio == containerRatio)
    {
        fitSize = containerSize;
    }
    else
    {
        fitSize.width = containerSize.width;
        fitSize.height = containerSize.width / imageRatio;
    }
    return fitSize;
}

// MARK: action

- (void)action_done
{
    UIImage *image = [self cropImageView:self.imageView toRect:self.cropRect zoomScale:1 containerView:self.view];
    // 原代码中的`zoomScale`参数导致bug
//    UIImage *image = [self cropImageView:self.imageView toRect:self.cropRect zoomScale:self.scrollView.zoomScale containerView:self.view];
    if (self.needRound) {
        image = [self circularClipImage:image];
    }
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
    CGFloat offsetX = (_scrollView.bounds.size.width > _scrollView.contentSize.width) ? ((_scrollView.bounds.size.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.bounds.size.height > _scrollView.contentSize.height) ? ((_scrollView.bounds.size.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}

/// 获得裁剪后的图片
- (UIImage *)cropImageView:(UIImageView *)imageView toRect:(CGRect)rect zoomScale:(double)zoomScale containerView:(UIView *)containerView
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 平移的处理
    CGRect imageViewRect = [imageView convertRect:imageView.bounds toView:containerView];
    CGPoint point = CGPointMake(imageViewRect.origin.x + imageViewRect.size.width / 2, imageViewRect.origin.y + imageViewRect.size.height / 2);
//    CGFloat xMargin = containerView.bounds.size.width - CGRectGetMaxX(rect) - rect.origin.x;
    CGPoint zeroPoint = CGPointMake(rect.origin.x + 0.5 * rect.size.width, rect.origin.y + 0.5 * rect.size.height);
    //CGPointMake((CGRectGetWidth(containerView.frame) - xMargin) / 2, containerView.center.y);
    CGPoint translation = CGPointMake(point.x - zeroPoint.x, point.y - zeroPoint.y);
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
    // 缩放的处理
    transform = CGAffineTransformScale(transform, zoomScale, zoomScale);
    
    UIImage *image = imageView.image;
    CGImageRef imageRef = [self newTransformedImage:transform
                                        sourceImage:image.CGImage
                                         sourceSize:image.size
                                        outputWidth:rect.size.width * [UIScreen mainScreen].scale
                                           cropSize:rect.size
                                      imageViewSize:imageViewRect.size];
    UIImage *cropedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropedImage;
}

- (CGImageRef)newTransformedImage:(CGAffineTransform)transform sourceImage:(CGImageRef)sourceImage sourceSize:(CGSize)sourceSize  outputWidth:(CGFloat)outputWidth cropSize:(CGSize)cropSize imageViewSize:(CGSize)imageViewSize
{
    CGImageRef source = [self newScaledImage:sourceImage toSize:sourceSize];
    
    CGFloat aspect = cropSize.height/cropSize.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL, outputSize.width, outputSize.height, CGImageGetBitsPerComponent(source), CGImageGetBytesPerRow(source), CGImageGetColorSpace(source), CGImageGetBitmapInfo(source));
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    // error
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width / cropSize.width, outputSize.height / cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width/2.0, cropSize.height / 2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    // error
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2, -imageViewSize.height/2.0, imageViewSize.width, imageViewSize.height), source);
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGImageRelease(source);
    return resultRef;
}

- (CGImageRef)newScaledImage:(CGImageRef)source toSize:(CGSize)size
{
    CGSize srcSize = size;
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextDrawImage(context, CGRectMake(0, 0, srcSize.width, srcSize.height), source);
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

/// 获取圆形图片
- (UIImage *)circularClipImage:(UIImage *)image
{
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
