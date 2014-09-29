//
//  AMPhotoAlbum.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAlbum.h"

@interface AMPhotoAlbum ()
{
    ALAssetsGroup *_assetsGroup;
    PHAssetCollection *_assetCollection;
    
    BOOL _hasGotPosterImage;
    UIImage *_posterImage;
}
@end

@implementation AMPhotoAlbum

+ (AMPhotoAlbum *)photoAlbumWithALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    return [[AMPhotoAlbum alloc] initWithALAssetsGroup: assetsGroup];
}

+ (AMPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection
{
    return [[AMPhotoAlbum alloc] initWithPHAssetCollection: assetCollection];
}

- (AMPhotoAlbum *)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self = [super init];
    if (self) {
        _assetsGroup = assetsGroup;
        [self commonInit];
    }
    return self;
}

- (AMPhotoAlbum *)initWithPHAssetCollection:(PHAssetCollection *)assetCollection
{
    self = [super init];
    if (self) {
        _assetCollection = assetCollection;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _hasGotPosterImage = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        _title = _assetCollection.localizedTitle;
    }
    else {
        _title = [_assetsGroup valueForProperty: ALAssetsGroupPropertyName];
    }
}

- (ALAssetsGroup *)asALAssetsGroup
{
    return _assetsGroup;
}

- (PHAssetCollection *)asPHAssetCollection
{
    return _assetCollection;
}

- (NSInteger)numberOfAssets
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:nil];
        NSUInteger number = fetchResult.count;
        if (NSNotFound == number) {
            return 0;
        }
        else {
            return number;
        }
    }
    else {
        return _assetsGroup.numberOfAssets;
    }
}

- (UIImage *)posterImage
{
    if (!_hasGotPosterImage) {
        _hasGotPosterImage = YES;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:nil];
            [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AMPhotoAsset *photoAsset = [AMPhotoAsset photoAssetWithPHAsset: obj];
                _posterImage = photoAsset.thumbnail;
                *stop = YES;
            }];
        }
        else {
            _posterImage = [UIImage imageWithCGImage: _assetsGroup.posterImage];
        }
        
    }
    return _posterImage;
}

@end
