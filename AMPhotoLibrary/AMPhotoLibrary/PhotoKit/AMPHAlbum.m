//
//  AMPHAlbum.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMPHAsset.h"
#import "AMPHAlbum.h"

@interface AMPHAlbum ()
{
    PHAssetCollection *_assetCollection;
    PHFetchResult *_fetchResult;
    
    BOOL _hasGotPosterImage;
    UIImage *_posterImage;
    
    AMAssetsFilter *_assetsFilter;
    BOOL _isUserLibrary;
}
@end

@implementation AMPHAlbum

@synthesize isUserLibrary = _isUserLibrary;
@synthesize assetsFilter = _assetsFilter;

+ (instancetype)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection {
    return [[[self class] alloc] initWithPHAssetCollection: assetCollection];
}

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection {
    self = [super init];
    if (self) {
        _assetCollection = assetCollection;
        _isUserLibrary = assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setNeedsUpdate];
}

- (id)wrappedInstance {
    return _assetCollection;
}

- (PHFetchResult *)fetchResult {
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

- (NSString *)title {
    NSString *title = _assetCollection.localizedTitle;
    return title;
}

- (NSInteger)numberOfAssets {
    NSUInteger number = self.fetchResult.count;
    if (NSNotFound == number) {
        return 0;
    }
    else {
        return number;
    }
}

- (UIImage *)posterImage {
    if (!_hasGotPosterImage) {
        _hasGotPosterImage = YES;
        NSEnumerationOptions options = 0;
        if (PHAssetCollectionTypeSmartAlbum == _assetCollection.assetCollectionType) {
            options = NSEnumerationReverse;
        }
        [self.fetchResult enumerateObjectsWithOptions:options usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            AMPHAsset *photoAsset = [AMPHAsset photoAssetWithPHAsset: obj];
            _posterImage = photoAsset.thumbnail;
            *stop = YES;
        }];
    }
    return _posterImage;
}

- (void)setAssetsFilter:(AMAssetsFilter *)assetsFilter
{
    if ([assetsFilter isEqual:self.assetsFilter]) {
        return;
    }
    _assetsFilter = assetsFilter;
    _fetchResult = nil;
}

- (void)setNeedsUpdate
{
    _hasGotPosterImage = NO;
    _posterImage = nil;
    _fetchResult = nil;
}

- (void)changed:(id)afterChanges
{
    _assetCollection = afterChanges;
    [self setNeedsUpdate];
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [self.fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (enumerationBlock) {
            id<AMPhotoAsset> photoAsset = [AMPHAsset photoAssetWithPHAsset: obj];
            enumerationBlock(photoAsset, idx, stop);
        }
    }];
    resultBlock(YES, nil);
}

@end
