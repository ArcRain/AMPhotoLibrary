//
//  AMALAlbum.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMALAsset.h"
#import "AMALAlbum.h"

@interface AMALAlbum ()
{
    ALAssetsGroup *_assetsGroup;
    
    BOOL _hasGotPosterImage;
    UIImage *_posterImage;
    
    AMAssetsFilter *_assetsFilter;
    BOOL _isUserLibrary;
}
@end

@implementation AMALAlbum

@synthesize isUserLibrary = _isUserLibrary;
@synthesize assetsFilter = _assetsFilter;

+ (instancetype)photoAlbumWithALAssetsGroup:(ALAssetsGroup *)assetsGroup {
    return [[[self class] alloc] initWithALAssetsGroup: assetsGroup];
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup {
    self = [super init];
    if (self) {
        _assetsGroup = assetsGroup;
        _isUserLibrary = [[_assetsGroup valueForProperty: ALAssetsGroupPropertyType] unsignedIntegerValue] == ALAssetsGroupLibrary;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setNeedsUpdate];
}

- (id)wrappedInstance {
    return _assetsGroup;
}

- (NSString *)title {
    NSString *title = [_assetsGroup valueForProperty: ALAssetsGroupPropertyName];
    return title;
}

- (NSInteger)numberOfAssets {
    return _assetsGroup.numberOfAssets;
}

- (UIImage *)posterImage {
    if (!_hasGotPosterImage) {
        _hasGotPosterImage = YES;
        _posterImage = [UIImage imageWithCGImage: _assetsGroup.posterImage];
    }
    return _posterImage;
}

- (void)setAssetsFilter:(AMAssetsFilter *)assetsFilter {
    if ([assetsFilter isEqual:_assetsFilter]) {
        return;
    }
    _assetsFilter = assetsFilter;
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

- (void)setNeedsUpdate {
    _hasGotPosterImage = NO;
    _posterImage = nil;
}

- (void)changed:(id)afterChanges {
    [self setNeedsUpdate];
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [_assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (nil == result) {
            resultBlock(YES, nil);
            return;
        }
        if (enumerationBlock) {
            id<AMPhotoAsset> asset = [AMALAsset photoAssetWithALAsset: result];
            enumerationBlock(asset, index, stop);
        }
    }];
}

@end
