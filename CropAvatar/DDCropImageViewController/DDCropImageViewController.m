//
//  DDCropImageViewController.m
//  CropAvatar
//
//  Created by 李亚洲 on 2017/3/14.
//  Copyright © 2017年 李亚洲. All rights reserved.
//

#import "DDCropImageViewController.h"

#define buttonHeight 40 // 底部 按钮 高度
#define paddingX 16 // 底部按钮两侧边距
#define paddingY 16 // 底部按钮上下边距
#define marginY 8 // 底部按钮间距
#define bottomViewHeight  (paddingY * 2 + buttonHeight * 3 + marginY * 2) // 底部视图高度

#define navigationBarHeight 64.0 // 导航栏所影响的高度

#define FixError 1

/*
 所有view和layer的frame都以self.view为基准。
 */

@interface DDCropImageViewController () <UIScrollViewDelegate>

@property (strong, nonatomic, readwrite) UIView *bottomView;
@property (strong, nonatomic, readwrite) UIImageView *imageView;
@property (strong, nonatomic, readwrite) UIScrollView *scrollView;

@property (assign, nonatomic, readwrite) CGRect cropRect; // 截图区域
@end

@implementation DDCropImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    //    self.edgesForExtendedLayout = UIRectEdgeNone;
    //    self.navigationController.navigationBarHidden = YES;
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:26/255.0 green:114/255.0 blue:230/255.0 alpha:1];
    self.title = @"编辑裁剪";
    
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

#pragma mark - action

- (void)action_cancel
{
    if (_delegate) {
        [_delegate cropImageViewControllerCanceled:self];
    }
}

- (void)action_album
{
    
}

- (void)action_camera
{
}

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

#pragma mark - private

- (void)_buildUI
{
    // 滚动视图
    [self _renderScrollView];
    
    // 透明黑色浮层
    [self _renderOverLayer];
    
    // 底部按钮视图
    [self _renderBottomView];
    
    // 导航栏
    [self _renderNavigationItem];
}

- (void)_renderNavigationItem {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"cancel" style:UIBarButtonItemStyleDone target:self action:@selector(action_cancel)];
}

- (void)_renderBottomView
{
    // bottom
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame) - bottomViewHeight, self.view.bounds.size.width, bottomViewHeight)];
    bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottomView];
    
    
    UIButton *albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [albumButton setTitle:@"相册" forState:UIControlStateNormal];
    [albumButton addTarget:self action:@selector(action_album) forControlEvents:UIControlEventTouchUpInside];
    [albumButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    albumButton.backgroundColor = [UIColor whiteColor];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraButton setTitle:@"拍照" forState:UIControlStateNormal];
    [cameraButton addTarget:self action:@selector(action_camera) forControlEvents:UIControlEventTouchUpInside];
    cameraButton.backgroundColor = [UIColor whiteColor];
    [cameraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setTitle:@"确定" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(action_done) forControlEvents:UIControlEventTouchUpInside];
    doneButton.backgroundColor = [UIColor whiteColor];
    [doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    
    albumButton.frame = CGRectMake(paddingX, paddingY, CGRectGetWidth(bottomView.bounds) - 2 * paddingX, buttonHeight);
    cameraButton.frame = CGRectMake(paddingX, CGRectGetMaxY(albumButton.frame) + marginY, CGRectGetWidth(albumButton.bounds), buttonHeight);
    doneButton.frame = CGRectMake(paddingX, CGRectGetMaxY(cameraButton.frame) + marginY, CGRectGetWidth(albumButton.bounds), buttonHeight);
    
    [bottomView addSubview:albumButton];
    [bottomView addSubview:cameraButton];
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
    UIScrollView *containScrollerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, navigationBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - navigationBarHeight)];
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
    
    CGFloat cropWidth = MIN(CGRectGetWidth(overLayer.frame), CGRectGetHeight(overLayer.frame) - CGRectGetHeight(self.bottomView.frame));
    if (self.cropWidth > 0) {
        cropWidth = MIN(self.cropWidth, cropWidth);
    }
    self.cropWidth = cropWidth;
    CGFloat cropX = CGRectGetWidth(overLayer.frame) * 0.5 - cropWidth * 0.5 + overLayer.frame.origin.x;
    CGFloat cropY = (CGRectGetHeight(overLayer.frame) - bottomViewHeight) * 0.5 - cropWidth * 0.5 + overLayer.frame.origin.y;
    self.cropRect = CGRectMake( cropX, cropY,cropWidth, cropWidth);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, overLayer.bounds);
    if (self.needRound) {
        CGPathAddEllipseInRect(path, NULL, CGRectMake(cropX - overLayer.frame.origin.x, cropY - overLayer.frame.origin.y, cropWidth, cropWidth));
    } else {
        CGPathAddRect(path, NULL, CGRectMake(cropX - overLayer.frame.origin.x, cropY - overLayer.frame.origin.y, cropWidth, cropWidth));
    }
    overLayer.path = path;
    
    [self.view.layer addSublayer:overLayer];
}

- (void)_renderImage
{
    if (self.sourceImage == nil)
    {
        if (_delegate)
        {
            NSError *error = [NSError errorWithDomain:@"com.dada.cropImage" code:-1 userInfo:@{@"reason":@"原始图像不能为空"}];
            [_delegate cropImageViewController:self occurError:error];
        }
        return;
    }
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
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
    
    [self refreshImageViewCenter];
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

/// 根据当前放大倍数(imageView的大小)，调整contentSize/contentInset使全部视图都能显示在截图区域
- (void)refreshScrollViewContentSize
{
    /// 因为增加contentSize只会在当前contentView的尾部增加大小
    /// 所以对于 right + bottom 的部分采用放大contentSie的方法使其能够出现在裁剪区域
    /// 对于 top + left 的部分，采用 contentInset 的方式使其能够显示在裁剪区域。
    
    // 计算右侧 contentSize 需要放大的 contentSize
    CGFloat contentWidthAdd = self.scrollView.bounds.size.width - CGRectGetMaxX(_cropRect);
    /// 计算底部应该增加的contentSize
    CGFloat contentHeightAdd = (MIN(_imageView.frame.size.height, self.scrollView.bounds.size.height) - self.cropRect.size.height) * 0.5;
    
    CGFloat newSizeW = self.scrollView.contentSize.width + contentWidthAdd;
    CGFloat newSizeH = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height) + contentHeightAdd;
    _scrollView.contentSize = CGSizeMake(newSizeW, newSizeH);
    _scrollView.alwaysBounceVertical = YES;
    
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (contentHeightAdd > 0) {
        inset.top = contentHeightAdd;
    }
    if (contentWidthAdd > 0) {
        inset.left = contentWidthAdd;
    }
    _scrollView.contentInset = inset;
}

- (void)refreshImageViewCenter
{
    // 当裁剪区域和滚动视图的center不重合时，使用translate使图片的center和裁剪区域的center保持一致
    CGPoint translate = CGPointMake(self.cropRect.origin.x + self.cropRect.size.width * 0.5 - self.scrollView.center.x, self.cropRect.origin.y + self.cropRect.size.height * 0.5 - self.scrollView.center.y);
    
    CGFloat offsetX = (_scrollView.bounds.size.width > _scrollView.contentSize.width) ? ((_scrollView.bounds.size.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.bounds.size.height > _scrollView.contentSize.height) ? ((_scrollView.bounds.size.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX + translate.x, _scrollView.contentSize.height * 0.5 + offsetY + translate.y);
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollView.contentInset = UIEdgeInsetsZero;
    scrollView.contentSize = _imageView.frame.size;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self refreshScrollViewContentSize];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshImageViewCenter];
}

#pragma mark - 画布截图

/// 获得裁剪后的图片
- (UIImage *)cropImageView:(UIImageView *)imageView toRect:(CGRect)rect zoomScale:(double)zoomScale containerView:(UIView *)containerView
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 平移的处理
    CGRect imageViewRect = [imageView convertRect:imageView.bounds toView:containerView];
    CGPoint point = CGPointMake(imageViewRect.origin.x + imageViewRect.size.width / 2, imageViewRect.origin.y + imageViewRect.size.height / 2);
    CGPoint zeroPoint = CGPointMake(rect.origin.x + 0.5 * rect.size.width, rect.origin.y + 0.5 * rect.size.height);
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
#if FixError
    if (context == NULL) {
        outputSize = cropSize;
        context = CGBitmapContextCreate(NULL, cropSize.width, cropSize.height, CGImageGetBitsPerComponent(source), CGImageGetBytesPerRow(source), CGImageGetColorSpace(source), CGImageGetBitmapInfo(source));
    }
#endif
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

/// 把原始图片转化成 “标准图片”
- (CGImageRef)newScaledImage:(CGImageRef)source toSize:(CGSize)size
{
    CGSize srcSize = size;
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextSetInterpolationQuality(context, kCGInterpolationDefault);
    
    CGContextDrawImage(context, CGRectMake(0, 0, srcSize.width, srcSize.height), source);
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

/// 截取圆形图片
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
