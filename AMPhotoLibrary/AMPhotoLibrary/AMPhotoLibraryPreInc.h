//
//  AMPhotoLibraryPreInc.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define __AMPHOTOLIB_USE_PHOTO__ 1

#if __AMPHOTOLIB_USE_PHOTO__
    #ifdef __IPHONE_8_0
        #import <Photos/Photos.h>
    #endif
#endif
