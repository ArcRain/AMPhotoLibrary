//
//  AMALAlbum.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMALAlbum : NSObject <AMPhotoAlbum>

+ (instancetype)photoAlbumWithALAssetsGroup:(ALAssetsGroup *)assetsGroup;
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup;

@end
