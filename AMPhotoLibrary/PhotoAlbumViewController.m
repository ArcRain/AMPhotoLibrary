//
//  PhotoAlbumViewController.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "PhotoAssetsViewController.h"
#import "PhotoAlbumViewController.h"
#import "AMPhotoLibrary.h"

NSString *const PhotoAlbumViewCellReuseIdentifier = @"PhotoAlbumViewCell";

@interface PhotoAlbumViewCell : UITableViewCell

- (void)configData:(AMPhotoAlbum *)data;

@end

@implementation PhotoAlbumViewCell

- (void)configData:(AMPhotoAlbum *)data
{
    self.textLabel.text = data.title;
    self.imageView.image = data.posterImage;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end

@interface PhotoAlbumViewController () <AMPhotoLibraryChangeObserver>
{
    NSMutableArray *_photoAlbums;
}
@end

@implementation PhotoAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = @"Photo Album";
    
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[PhotoAlbumViewCell class] forCellReuseIdentifier: PhotoAlbumViewCellReuseIdentifier];
    
    [[AMPhotoLibrary sharedPhotoLibrary] registerChangeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [AMPhotoLibrary requestAuthorization:^(AMAuthorizationStatus status) {
        if (status == AMAuthorizationStatusAuthorized) {
            NSMutableArray *tempArray = [NSMutableArray array];
            [[AMPhotoLibrary sharedPhotoLibrary] enumerateAlbums:^(AMPhotoAlbum *album, BOOL *stop) {                
                [tempArray addObject: album];
            } resultBlock:^(BOOL success, NSError *error) {
                _photoAlbums = tempArray;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _photoAlbums.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoAlbumViewCell *cell = (PhotoAlbumViewCell *)[tableView dequeueReusableCellWithIdentifier:PhotoAlbumViewCellReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    AMPhotoAlbum *albumData = _photoAlbums[indexPath.row];
    [cell configData: albumData];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath: indexPath animated:NO];
    
    CGFloat itemWidth = floorf((tableView.bounds.size.width - 1 - 1 - 2 * 3) / 4);
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(2, 1, 2, 1);
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
    flowLayout.minimumInteritemSpacing = 2.f;
    flowLayout.minimumLineSpacing = 2.f;
    
    AMPhotoAlbum *albumData = _photoAlbums[indexPath.row];
    PhotoAssetsViewController *viewController = [[PhotoAssetsViewController alloc] initWithCollectionViewLayout:flowLayout];
    viewController.photoAlbum = albumData;
    [self.navigationController pushViewController: viewController animated:YES];
}

#pragma mark - AMPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(AMPhotoChange *)changeInstance
{
    [_photoAlbums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AMPhotoAlbum *photoAlbum = (AMPhotoAlbum *)obj;
        AMPhotoChangeDetails* changeDetails = [changeInstance changeDetailsForObject:photoAlbum];
        if (nil == changeDetails) {
            return;
        }
        //For test
        /*
        id beforeObj = changeDetails.objectBeforeChanges;
        id afterObj = changeDetails.objectAfterChanges;
        BOOL wasDeleted = changeDetails.objectWasDeleted;
        BOOL contentChanged = changeDetails.objectWasChanged;
         */
    }];
}

@end
