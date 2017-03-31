//
//  ViewController.m
//  CropAvatar
//
//  Created by 李亚洲 on 2017/3/14.
//  Copyright © 2017年 李亚洲. All rights reserved.
//

#import "ViewController.h"
#import "DDCropImageViewController.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, DDCropImageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)action_camera
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选取" message:@"选取" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //    picker.allowsEditing = YES;
        picker.delegate = self;
        [self showViewController:picker sender:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //    picker.allowsEditing = YES;
        picker.delegate = self;
        [self showViewController:picker sender:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage* image=[info objectForKey:UIImagePickerControllerOriginalImage];
    
    // 解决`UIImagePickerController`选择图片旋转90°问题
    UIImageOrientation imageOrientation=image.imageOrientation;
    if(imageOrientation!=UIImageOrientationUp)
    {
        // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
        // 以下为调整图片角度的部分
        UIGraphicsBeginImageContext(image.size);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 调整图片角度完毕
    }
    
    DDCropImageViewController *cropVc = [[DDCropImageViewController alloc] init];
    cropVc.sourceImage = image;
    cropVc.needRound = YES;
    cropVc.delegate = self;
    [picker pushViewController:cropVc animated:YES];
}

#pragma mark - DDCropImageViewControllerDelegate

- (void)cropImageViewController:(DDCropImageViewController *)controller occurError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropImageViewControllerCanceled:(DDCropImageViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropImageViewController:(DDCropImageViewController *)controller didFinish:(UIImage *)editedImage
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imageView.image = editedImage;
}

@end
