//
//  AMPHChange.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoChange.h"

@interface AMPHChange : NSObject<AMPhotoChange>

+ (instancetype)changeWithPHChange:(PHChange *)changeInstance;
- (instancetype)initWithPHChange:(PHChange *)changeInstance;

- (void)setAlbumCreated:(BOOL)created;
- (void)setAlbumDeleted:(BOOL)deleted;

@end

@interface AMPHChangeDetails : NSObject<AMPhotoChangeDetails>

+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails;
- (instancetype)initWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails;

@end
