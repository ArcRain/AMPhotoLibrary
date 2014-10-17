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

- (AMPhotoChangeDetails *)changeDetailsForObject:(NSObject *)object;

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails : NSObject

@property (nonatomic, assign, readonly) BOOL objectHasChanged;

@end
