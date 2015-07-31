//
//  AMPhotoLibrary.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#ifdef __IPHONE_8_0
    #import <Photos/Photos.h>
    #ifndef __AMPHOTOLIB_USE_PHOTO__
    #define __AMPHOTOLIB_USE_PHOTO__
    #endif
#endif

/*
//Only ALAssetsLibrary without __AMPHOTOLIB_USE_PHOTO__
#ifdef __AMPHOTOLIB_USE_PHOTO__
#undef __AMPHOTOLIB_USE_PHOTO__
#endif
 */

#import "AMPhotoManager.h"

@interface AMPhotoLibrary : NSObject <AMPhotoManager>

+ (instancetype)sharedPhotoLibrary;
- (void)registerChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;

@end
