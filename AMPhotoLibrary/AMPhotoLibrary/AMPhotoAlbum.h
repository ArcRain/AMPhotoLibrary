//
//  AMPhotoAlbum.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMPhotoAlbum : NSObject

@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, assign) NSInteger numberOfAssets;
@property (nonatomic, readonly, strong) UIImage *posterImage;

+ (AMPhotoAlbum *)photoAlbumWithALAssetsGroup:(ALAssetsGroup *)assetsGroup;
+ (AMPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection;

- (ALAssetsGroup *)asALAssetsGroup;
- (PHAssetCollection *)asPHAssetCollection;

@end
