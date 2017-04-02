//
//  AMPHAlbum.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMPHAlbum : NSObject <AMPhotoAlbum>

@property (nonatomic, readonly, strong) PHFetchResult *fetchResult;

+ (instancetype)photoAlbumWithPHAssetCollection:(PHAssetCollection *)assetCollection;
- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)assetCollection;

@end
