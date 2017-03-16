//
//  DDCropImageViewController.h
//  CropAvatar
//
//  Created by 李亚洲 on 2017/3/14.
//  Copyright © 2017年 李亚洲. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDCropImageViewController;

@protocol DDCropImageViewControllerDelegate <NSObject>
- (void)cropImageViewController:(nonnull DDCropImageViewController *)controller didFinish:(nonnull UIImage *)editedImage;
- (void)cropImageViewController:(nonnull DDCropImageViewController *)controller occurError:(nonnull NSError *)error;
- (void)cropImageViewControllerCanceled:(nonnull DDCropImageViewController *)controller;
@end

@interface DDCropImageViewController : UIViewController
@property (nonnull, strong, nonatomic, readwrite) UIImage *sourceImage;
@property (assign, nonatomic, readwrite) BOOL needRound;
//@property (assign, nonatomic, readwrite) float cropWidth;

@property (weak, nullable, readwrite) id<DDCropImageViewControllerDelegate> delegate;
@end
