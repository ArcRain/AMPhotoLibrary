//
//  AMPhotoManager.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AMPhotoAsset.h"
#import "AMPhotoAlbum.h"
#import "AMPhotoChange.h"

typedef NS_ENUM(NSUInteger, AMAuthorizationStatus) {
    AMAuthorizationStatusNotDetermined = 0, // User has not yet made a choice with regards to this application
    AMAuthorizationStatusRestricted,        // This application is not authorized to access photo data.
    // The user cannot change this application’s status, possibly due to active restrictions
    //   such as parental controls being in place.
    AMAuthorizationStatusDenied,            // User has explicitly denied this application access to photos data.
    AMAuthorizationStatusAuthorized         // User has authorized this application to access photos data.
};

#pragma mark - AMPhotoLibraryChangeObserver
@protocol AMPhotoLibraryChangeObserver <NSObject>

@optional
- (void)photoLibraryDidChange:(AMPhotoChange *)changeInstance;

@end

#pragma mark - AMPhotoManager
/*
 Not all function is thread safety.
 You SHOULD run UI code in main thread when you want to update UI in block.
 */
@protocol AMPhotoManager <NSObject>

@required

//AuthorizationStatus check
+ (AMAuthorizationStatus)authorizationStatus;
+ (void)requestAuthorization:(void(^)(AMAuthorizationStatus status))handler;

- (void)registerChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer;

- (void)createAlbum:(NSString *)title resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)checkAlbum:(NSString *)title resultBlock:(AMPhotoManagerCheckBlock)resultBlock;

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)deleteAssets:(NSArray *)assets resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)deleteAlbums:(NSArray *)albums resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)writeImage:(UIImage *)image toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;
- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock;

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(AMPhotoManagerResultBlock)resultBlock;

@end
