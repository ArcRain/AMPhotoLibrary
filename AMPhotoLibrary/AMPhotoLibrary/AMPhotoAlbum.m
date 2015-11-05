//
//  AMPhotoAlbum.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAlbum.h"

@interface AMAssetsFilter ()

@property (nonatomic, assign) BOOL includeImage;
@property (nonatomic, assign) BOOL includeVideo;
@property (nonatomic, assign) BOOL includeAudio;

@end

@implementation AMAssetsFilter

+ (AMAssetsFilter *)allAssets
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = YES;
    filter.includeAudio = YES;
    return filter;
}

+ (AMAssetsFilter *)allImages
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = NO;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allVideos
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = YES;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allAudios
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = NO;
    filter.includeAudio = YES;
    return filter;
}

- (BOOL)isEqual:(id)object
{
    AMAssetsFilter *filter = (AMAssetsFilter *)object;
    return (self.includeImage == filter.includeImage) && (self.includeVideo == filter.includeVideo) && (self.includeAudio == filter.includeAudio);
}

@end

@interface AMPhotoAlbum ()
{
    ALAssetsGroup *_assetsGroup;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHAssetCollection *_assetCollection;
    PHFetchResult *_fetchResult;
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

- (PHFetchResult *)fetchResult
{
    if (nil == _fetchResult) {
        if (nil == self.assetsFilter) {
            _fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:nil];
        }
        else {
            NSString *queryString = @"";
            if (self.assetsFilter.includeImage) {
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeImage];
            }
            if (self.assetsFilter.includeVideo) {
                if (queryString.length > 0) {
                    queryString = [queryString stringByAppendingString:@" || "];
                }
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeVideo];
            }
            if (self.assetsFilter.includeAudio) {
                if (queryString.length > 0) {
                    queryString = [queryString stringByAppendingString:@" || "];
                }
                queryString = [queryString stringByAppendingFormat:@"(mediaType == %ld)", (long)PHAssetMediaTypeVideo];
            }
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.predicate = [NSPredicate predicateWithFormat:queryString];
            _fetchResult = [PHAsset fetchAssetsInAssetCollection: _assetCollection options:fetchOptions];
        }
    }
    return _fetchResult;
}

#endif

- (void)commonInit
{
    [self setNeedsUpdate];
}

- (NSString *)title
{
    NSString *title = @"";
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        title = _assetCollection.localizedTitle;
    }
    else
#endif
    {
        title = [_assetsGroup valueForProperty: ALAssetsGroupPropertyName];
    }
    return title;
}

- (NSInteger)numberOfAssets
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        NSUInteger number = self.fetchResult.count;
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
            NSEnumerationOptions options = 0;
            if (PHAssetCollectionTypeSmartAlbum == self.asPHAssetCollection.assetCollectionType) {
                options = NSEnumerationReverse;
            }
            [self.fetchResult enumerateObjectsWithOptions:options usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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

- (void)setAssetsFilter:(AMAssetsFilter *)assetsFilter
{
    if ([assetsFilter isEqual:_assetsFilter]) {
        return;
    }
    _assetsFilter = assetsFilter;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        _fetchResult = nil;
    }
    else
#endif
    {
        if (nil == self.assetsFilter) {
            [_assetsGroup setAssetsFilter:nil];
        }
        else if (self.assetsFilter.includeVideo && self.assetsFilter.includeImage) {
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
        }
        else if (self.assetsFilter.includeImage) {
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        else if (self.assetsFilter.includeVideo) {
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
        }
    }
}

- (void)setNeedsUpdate
{
    _hasGotPosterImage = NO;
    _posterImage = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    _fetchResult = nil;
#endif
}

- (void)changed:(id)afterChanges
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if ([afterChanges isKindOfClass:[PHAssetCollection class]]) {
        _assetCollection = afterChanges;
    }
#endif
    [self setNeedsUpdate];
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    __block BOOL isStop = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        [self.fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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
