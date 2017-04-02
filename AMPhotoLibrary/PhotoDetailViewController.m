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

@property (nonatomic, strong) AVPlayer *avPlayer;
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
        
        [AMPhotoAssetUtility fetchAsset:self.photoAsset rawData:^(NSData *rawData, AVPlayerItem *playerItem) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (nil != playerItem) {
                        _avPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
                        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
                        layer.frame = self.view.bounds;
                        layer.videoGravity=AVLayerVideoGravityResizeAspect;
                        [self.view.layer addSublayer:layer];
                        [self.avPlayer play];
                    }
                });
        }];
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
