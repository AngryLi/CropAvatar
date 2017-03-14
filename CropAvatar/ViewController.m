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
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self showViewController:picker sender:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    DDCropImageViewController *cropVc = [[DDCropImageViewController alloc] init];
    cropVc.sourceImage = originalImage;
    cropVc.delegate = self;
    [picker pushViewController:cropVc animated:YES];
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
