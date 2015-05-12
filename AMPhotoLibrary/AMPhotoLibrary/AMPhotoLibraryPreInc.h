//
//  AMPhotoLibraryPreInc.h
//  wildtransfer
//
//  Created by ArcRain on 4/7/15.
//  Copyright (c) 2015 Palmto Team. All rights reserved.
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
