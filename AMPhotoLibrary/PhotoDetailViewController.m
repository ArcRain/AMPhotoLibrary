//
//  PhotoDetailViewController.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/29/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

@import MediaPlayer;
#import "PhotoDetailViewController.h"

@interface PhotoDetailViewController ()

@property (nonatomic, strong) MPMoviePlayerController *videoController;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PhotoDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.photoAsset.mediaType == AMAssetMediaTypeImage) {
        _imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview: _imageView];
    }
    else if (self.photoAsset.mediaType == AMAssetMediaTypeVideo) {
        NSURL *url = self.photoAsset.assetURL;
        _videoController = [[MPMoviePlayerController alloc] initWithContentURL:url];
        [_videoController prepareToPlay];
        CGRect frame = self.view.bounds;
        frame.origin.y = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
        frame.size.height -= frame.origin.y;
        _videoController.view.frame = frame;
        [self.view addSubview:_videoController.view];
    }
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(didClickDelete)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    if (self.photoAsset.mediaType == AMAssetMediaTypeImage) {
        self.imageView.image = self.photoAsset.fullScreenImage;
        //If you want to get image in async mode, you can use this sample code.
        /*
         [AMPhotoAsset fetchAsset:self.photoAsset withImageType:AMAssetImageTypeFullScreen imageResult:^(UIImage *image) {
         self.imageView.image = image;
         }];
         */
    }
    else if (self.photoAsset.mediaType == AMAssetMediaTypeVideo) {
        [_videoController play];
    }
}

- (void)didClickDelete
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Do you want to delete this file?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[AMPhotoLibrary sharedPhotoLibrary] deleteAssets:@[self.photoAsset] resultBlock:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }
        }];
    }];
    [alertController addAction:delete];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
