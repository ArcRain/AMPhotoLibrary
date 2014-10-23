//
//  AMPhotoChange.h
//  AMPhotoLibrary
//
//  Created by Anwu Yang on 10/17/14.
//  Copyright (c) 2014 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMPhotoChangeDetails;

#pragma mark - AMPhotoChange
@interface AMPhotoChange : NSObject

// the object is AMPhotoAsset/AMPhotoAlbum
- (AMPhotoChangeDetails *)changeDetailsForObject:(id)object;

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails : NSObject

// the object in the state before this change (returns the object that was passed in to changeDetailsForObject:)
@property (atomic, strong, readonly) id objectBeforeChanges;

// the object in the state after this change
@property (atomic, strong, readonly) id objectAfterChanges;

// YES if the image or video content for this object has been changed
@property (atomic, readonly) BOOL objectWasChanged;

// YES if the object was deleted
@property (atomic, readonly) BOOL objectWasDeleted;

@end
