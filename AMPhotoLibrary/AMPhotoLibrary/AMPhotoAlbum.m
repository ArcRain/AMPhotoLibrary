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
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHAssetCollection *_assetCollection;
#endif
    
    BOOL _hasGotPosterImage;
    UIImage *_posterImage;
}
@end

@implementation AMPhotoAlbum

+ (AMPhotoAlbum *)photoAlbumWithALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    return [[AMPhotoAlbum alloc] initWithALAssetsGroup: assetsGroup];
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

- (ALAssetsGroup *)asALAssetsGroup
{
    return _assetsGroup;
}

#ifdef __AMPHOTOLIB_USE_PHOTO__

+ (AMPhotoAlbum *)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection
{
    return [[AMPhotoAlbum alloc] initWithPHAssetCollection: assetCollection];
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

- (PHAssetCollection *)asPHAssetCollection
{
    return _assetCollection;
}

#endif

- (void)commonInit
{
    _hasGotPosterImage = NO;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        _title = _assetCollection.localizedTitle;
    }
    else
#endif
    {
        _title = [_assetsGroup valueForProperty: ALAssetsGroupPropertyName];
    }
}

- (NSInteger)numberOfAssets
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
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
    else
#endif
    {
        return _assetsGroup.numberOfAssets;
    }
}

- (UIImage *)posterImage
{
    if (!_hasGotPosterImage) {
        _hasGotPosterImage = YES;
        
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:nil];
            [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AMPhotoAsset *photoAsset = [AMPhotoAsset photoAssetWithPHAsset: obj];
                _posterImage = photoAsset.thumbnail;
                *stop = YES;
            }];
        }
        else
#endif
        {
            _posterImage = [UIImage imageWithCGImage: _assetsGroup.posterImage];
        }
    }
    return _posterImage;
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    __block BOOL isStop = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        _fetchResult = [PHAsset fetchAssetsInAssetCollection:_assetCollection options: nil];
        [_fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (enumerationBlock) {
                AMPhotoAsset *photoAsset = [AMPhotoAsset photoAssetWithPHAsset: obj];
                enumerationBlock(photoAsset, idx, stop);
                isStop = *stop;
            }
        }];
        resultBlock(YES, nil);
    }
    else
#endif
    {
        [_assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (nil == result) {
                resultBlock(YES, nil);
                return;
            }
            if (enumerationBlock) {
                AMPhotoAsset *asset = [AMPhotoAsset photoAssetWithALAsset: result];
                enumerationBlock(asset, index, stop);
            }        
        }];
    }
}

@end
