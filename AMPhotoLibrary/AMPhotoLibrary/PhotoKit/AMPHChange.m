//
//  AMPHChange.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMPHAsset.h"
#import "AMPHAlbum.h"
#import "AMPHChange.h"

#pragma mark - AMPHChange
@interface AMPHChange ()
{
    PHChange *_changeInstance;
    BOOL _isAlbumCreated;
    BOOL _isAlbumDeleted;
}
@end

@implementation AMPHChange

@synthesize isAlbumCreated = _isAlbumCreated;
@synthesize isAlbumDeleted = _isAlbumDeleted;

+ (instancetype)changeWithPHChange:(PHChange *)changeInstance {
    return [[[self class] alloc] initWithPHChange:changeInstance];
}

- (instancetype)initWithPHChange:(PHChange *)changeInstance {
    self = [super init];
    if (self) {
        _changeInstance = changeInstance;
        _isAlbumCreated = NO;
        _isAlbumDeleted = NO;
    }
    return self;
}

- (void)setAlbumCreated:(BOOL)created
{
    _isAlbumCreated = created;
}

- (void)setAlbumDeleted:(BOOL)deleted
{
    _isAlbumDeleted = deleted;
}

- (id<AMPhotoChangeDetails>)changeDetailsForObject:(id)object {
    id<AMPhotoChangeDetails> changeDetails = nil;
    if ([object isKindOfClass:[AMPHAsset class]]) {
        AMPHAsset *asset = (AMPHAsset *)object;
        changeDetails = [AMPHChangeDetails changeDetailsWithPHObjectChangeDetails:[_changeInstance changeDetailsForObject:asset.wrappedInstance] PHFetchResultChangeDetails:nil];
    }
    else if ([object isKindOfClass:[AMPHAlbum class]]) {
        AMPHAlbum *album = (AMPHAlbum *)object;
        changeDetails = [AMPHChangeDetails changeDetailsWithPHObjectChangeDetails:[_changeInstance changeDetailsForObject:album.wrappedInstance] PHFetchResultChangeDetails:[_changeInstance changeDetailsForFetchResult:album.fetchResult]];
    }
    return changeDetails;
}

@end

#pragma mark - AMPHChangeDetails
@interface AMPHChangeDetails ()
{
    PHObjectChangeDetails *_changeDetails;
    PHFetchResultChangeDetails *_resultChangeDetails;
}
@end

@implementation AMPHChangeDetails

+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails {
    if ((nil == changeDetails) && (nil == fetchResultChangeDetails)) {
        return nil;
    }
    return [[[self class] alloc] initWithPHObjectChangeDetails:changeDetails PHFetchResultChangeDetails:fetchResultChangeDetails];
}

- (instancetype)initWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails {
    self = [super init];
    if (self) {
        _changeDetails = changeDetails;
        _resultChangeDetails = fetchResultChangeDetails;
    }
    return self;
}

- (id)objectBeforeChanges
{
    if (nil != _changeDetails) {
        return _changeDetails.objectBeforeChanges;
    }
    else {
        return nil;
    }

}

- (id)objectAfterChanges
{
    if (nil != _changeDetails) {
        return _changeDetails.objectAfterChanges;
    }
    else {
        return nil;
    }
}

- (BOOL)objectWasChanged
{
    __block BOOL wasChanged = NO;
    if (nil != _changeDetails) {
        //For asset
        wasChanged = _changeDetails.assetContentChanged;
        //For collection property changed
        wasChanged |= (![_changeDetails.objectBeforeChanges isEqual:_changeDetails.objectAfterChanges]);
    }
    if (nil != _resultChangeDetails) {
        //For assets in collection changed
        wasChanged |= _resultChangeDetails.fetchResultBeforeChanges.count != _resultChangeDetails.fetchResultAfterChanges.count;
    }
    return wasChanged;
}

- (BOOL)objectWasDeleted
{
    __block BOOL wasDeleted = NO;
    if (nil != _changeDetails) {
        wasDeleted = _changeDetails.objectWasDeleted;
    }
    return wasDeleted;
}

@end
