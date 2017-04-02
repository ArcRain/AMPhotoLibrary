//
//  AMPhotoChange.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMPhotoChangeDetails;

#pragma mark - AMPhotoChange
@protocol AMPhotoChange<NSObject>

@required
@property (atomic, assign, readonly) BOOL isAlbumCreated;
@property (atomic, assign, readonly) BOOL isAlbumDeleted;

// the object is AMPhotoAsset/AMPhotoAlbum
- (id<AMPhotoChangeDetails>)changeDetailsForObject:(id)object;

@end

#pragma mark - AMPhotoChangeDetails
@protocol AMPhotoChangeDetails<NSObject>

// the object in the state before this change (returns the object that was passed in to changeDetailsForObject:)
@property (atomic, strong, readonly) id objectBeforeChanges;

// the object in the state after this change
@property (atomic, strong, readonly) id objectAfterChanges;

// YES if the image or video content for this object has been changed
@property (atomic, readonly) BOOL objectWasChanged;

// YES if the object was deleted
@property (atomic, readonly) BOOL objectWasDeleted;

@end
