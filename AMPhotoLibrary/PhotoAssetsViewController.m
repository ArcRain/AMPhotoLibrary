//
//  PhotoAssetsViewController.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "PhotoAssetsViewController.h"
#import "AMPhotoLibrary.h"

NSString *const PhotoAssetsViewCellReuseIdentifier = @"PhotoAssetsViewCell";

@interface PhotoAssetsViewCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *duration;
@property (nonatomic, strong) UIImageView *imageView;
- (void)configData:(AMPhotoAsset *)data;

@end

@implementation PhotoAssetsViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _imageView.center = CGPointMake(frame.size.width * 0.5, frame.size.height * 0.5);
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview: _imageView];
        
        _duration = [[UILabel alloc] initWithFrame: CGRectMake(frame.size.width - 54, 4, 50, 20)];
        _duration.backgroundColor = [UIColor clearColor];
        _duration.hidden = YES;
        _duration.textColor = [UIColor whiteColor];
        _duration.textAlignment = NSTextAlignmentRight;
        _duration.font = [UIFont systemFontOfSize:12.f];
        [self.contentView addSubview:_duration];
    }
    return self;
}

- (void)configData:(AMPhotoAsset *)data
{
    self.imageView.image = data.thumbnail;
    if (data.mediaType == AMAssetMediaTypeVideo) {
        long duration = data.duration;
        long hour = duration / 3600;
        long min = (duration - 3600 * hour) / 360;
        long sec = (long)(data.duration) % 60;
        _duration.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hour, min, sec];
        _duration.hidden = NO;
    }
}

- (void)prepareForReuse
{
    _duration.hidden = YES;
}

@end


@interface PhotoAssetsViewController ()
{
    NSMutableArray *_photoAssets;
}
@end

@implementation PhotoAssetsViewController

static NSString * const reuseIdentifier = @"UICollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[PhotoAssetsViewCell class] forCellWithReuseIdentifier:PhotoAssetsViewCellReuseIdentifier];
    
    // Do any additional setup after loading the view.
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
    
    NSMutableArray *tempArray = [NSMutableArray array];
    [self.photoAlbum enumerateAssets:^(AMPhotoAsset *asset, NSUInteger index, BOOL *stop) {
        [tempArray addObject: asset];
    } resultBlock:^(BOOL success, NSError *error) {
        _photoAssets = tempArray;
        [self.collectionView reloadData];
    }];
}

- (void)didClickDelete
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"Do you want to delete this album?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[AMPhotoLibrary sharedPhotoLibrary] deleteAlbums:@[self.photoAlbum] resultBlock:^(BOOL success, NSError *error) {
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoAssetsViewCell *cell = (PhotoAssetsViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:PhotoAssetsViewCellReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    AMPhotoAsset *asset = (AMPhotoAsset *)_photoAssets[indexPath.item];
    [cell configData: asset];
    
    //If you want to get image in async mode, you can use this sample code.
    /*
    __weak PhotoAssetsViewCell *weakCell = cell;
    [AMPhotoAsset fetchAsset:asset withImageType:AMAssetImageTypeThumbnail imageResult:^(UIImage *image) {
        NSIndexPath *currentIndexPath = [collectionView indexPathForCell:weakCell];
        if ([currentIndexPath isEqual:indexPath]) {
            weakCell.imageView.image = image;
        }
    }];
     */
    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AMPhotoAsset *asset = (AMPhotoAsset *)_photoAssets[indexPath.item];
    PhotoDetailViewController *detailViewController = [PhotoDetailViewController new];
    detailViewController.photoAsset = asset;
    [self.navigationController pushViewController: detailViewController animated:YES];
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
