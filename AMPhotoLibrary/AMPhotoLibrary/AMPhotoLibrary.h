//
//  AMPhotoLibrary.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoManager.h"

@interface AMPhotoLibrary : NSObject <AMPhotoManager>

+ (instancetype)sharedPhotoLibrary;
- (void)registerChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;

@end
