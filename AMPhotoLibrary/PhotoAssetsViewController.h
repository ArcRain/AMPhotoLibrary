//
//  PhotoAssetsViewController.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMPhotoAlbum;
@interface PhotoAssetsViewController : UICollectionViewController

@property (nonatomic, strong) AMPhotoAlbum *photoAlbum;

@end
