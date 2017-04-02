//
//  AMPHAsset.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMPHAsset.h"
#import "AMPhotoAssetUtility.h"

@interface AMPHAsset ()
{
    PHAsset *_phAsset;
    AMAssetMediaType _mediaType;
    unsigned long long _fileSize;
    
    BOOL _hasGotInfo;
    BOOL _hasGotFullMetaData;
    NSMutableDictionary *_metaData;
    NSURL *_assetURL;
    NSString *_UTI;
    NSString *_mimeType;
    NSString *_localIdentifier;
    
    UIImageOrientation _orientation;
    
    NSTimeInterval _duration;
}
@end

@implementation AMPHAsset

+ (instancetype)photoAssetWithPHAsset:(PHAsset *)asset {
    return [[[self class] alloc] initWithPHAsset: asset];
}

- (instancetype)initWithPHAsset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        _phAsset = asset;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _hasGotInfo = NO;
    _hasGotFullMetaData = NO;
    _duration = 0.f;
    _orientation = UIImageOrientationUp;
    
    switch (_phAsset.mediaType) {
        case PHAssetMediaTypeImage:
            _mediaType = AMAssetMediaTypeImage;
            break;
        case PHAssetMediaTypeVideo:
            _mediaType = AMAssetMediaTypeVideo;
            _duration = _phAsset.duration;
            break;
        case PHAssetMediaTypeAudio:
            _mediaType = AMAssetMediaTypeAudio;
            break;
        default:
            _mediaType = AMAssetMediaTypeUnknown;
            break;
    }
}

- (id)wrappedInstance {
    return _phAsset;
}

- (AMAssetMediaType)mediaType {
    return _mediaType;
}

- (CGSize)dimensions {
    return CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
}

enum {
    kAMASSETMETADATA_PENDINGREADS = 1,
    kAMASSETMETADATA_ALLFINISHED = 0
};

- (NSDictionary *)metadata {
    if (!_hasGotFullMetaData) {
        _hasGotFullMetaData = YES;
        
        if (PHAssetMediaTypeImage == _mediaType) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.version = PHImageRequestOptionsVersionCurrent;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.synchronous = YES;
            
            [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                if (NULL != source) {
                    _metaData = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
                    CFRelease(source);
                }
            }];
        }
        else if (PHAssetMediaTypeVideo == _mediaType) {
            PHVideoRequestOptions *request = [PHVideoRequestOptions new];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            request.networkAccessAllowed = YES;
            
            NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
            [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                
                _metaData = [NSMutableDictionary dictionary];
                NSArray *commonMetaData = playerItem.asset.commonMetadata;
                for (AVMetadataItem *item in commonMetaData) {
                    _metaData[item.commonKey] = item.value;
                }
                
                [assetReadLock lock];
                [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
            }];
            [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
            [assetReadLock unlock];
            assetReadLock = nil;
        }
    }
    return _metaData;
}

- (NSDate *)creationDate {
    return _phAsset.creationDate;
}

- (CLLocation *)location {
    return _phAsset.location;
}

- (NSString *)localIdentifier {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _localIdentifier;
}

- (NSURL *)assetURL {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _assetURL;
}

- (unsigned long long)fileSize {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _fileSize;
}

- (UIImageOrientation)orientation {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _orientation;
}

- (NSString *)UTI {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _UTI;
}

- (NSString *)mimeType {
    if (!_hasGotInfo) {
        [self getInfo];
    }
    return _mimeType;
}

- (UIImage *)thumbnail {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeThumbnail syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)aspectRatioThumbnail {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeAspectRatioThumbnail syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullScreenImage {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeFullScreen syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (UIImage *)fullResolutionImage {
    __block UIImage *image = nil;
    [[self class] fetchAsset:self withImageType:AMAssetImageTypeFullResolution syncMode:YES completion:^(UIImage *result) {
        image = result;
    }];
    return image;
}

- (NSData *)imageFileData {
    if (AMAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.resizeMode = PHImageRequestOptionsResizeModeNone;
    request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = YES;
    
    __block NSData *imageFileData = nil;
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        imageFileData = imageData;
    }];
    return imageFileData;
}

- (NSTimeInterval)duration {
    return _duration;
}

- (void)getInfo {
    if (!_hasGotInfo) {
        _hasGotInfo = YES;
        if (PHAssetMediaTypeImage == _mediaType) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.version = PHImageRequestOptionsVersionCurrent;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.synchronous = YES;
            
            [[PHCachingImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                _fileSize = imageData.length;
                _UTI = dataUTI;
                _localIdentifier = _phAsset.localIdentifier;
                _assetURL = [info objectForKey:@"PHImageFileURLKey"];
                _orientation = orientation;
            }];
        }
        else if (PHAssetMediaTypeVideo == _mediaType) {
            PHVideoRequestOptions *request = [PHVideoRequestOptions new];
            request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            request.version = PHVideoRequestOptionsVersionCurrent;
            request.networkAccessAllowed = YES;
            
            NSConditionLock* assetReadLock = [[NSConditionLock alloc] initWithCondition:kAMASSETMETADATA_PENDINGREADS];
            [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:_phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                NSArray *URLs = [AMPhotoAssetUtility fetchPlayerItemURLs:playerItem];
                NSURL *videoURL = [URLs firstObject];
                NSNumber *fileSize = nil;;
                if ([videoURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil]) {
                    _fileSize = [fileSize unsignedLongLongValue];
                }
                else {
                    _fileSize = 0;
                }
                _UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([videoURL pathExtension]), NULL));
                _localIdentifier = _phAsset.localIdentifier;
                _assetURL = videoURL;
                
                [assetReadLock lock];
                [assetReadLock unlockWithCondition:kAMASSETMETADATA_ALLFINISHED];
            }];
            [assetReadLock lockWhenCondition:kAMASSETMETADATA_ALLFINISHED];
            [assetReadLock unlock];
            assetReadLock = nil;
        }
    }
    CFStringRef UTI = (__bridge CFStringRef)_UTI;
    if (NULL != UTI) {
        _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    }
}

+ (void)fetchAsset:(id<AMPhotoAsset>)asset rawData:(void (^)(NSData *, AVPlayerItem *))resultBlock {
    PHAsset *phAsset = asset.wrappedInstance;
    if (AMAssetMediaTypeImage == asset.mediaType) {
        PHImageRequestOptions *request = [PHImageRequestOptions new];
        request.resizeMode = PHImageRequestOptionsResizeModeNone;
        request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        request.version = PHImageRequestOptionsVersionCurrent;
        request.synchronous = YES;
        request.networkAccessAllowed = YES;
        
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            resultBlock(imageData, nil);
        }];
    }
    else if (AMAssetMediaTypeVideo == asset.mediaType) {
        PHVideoRequestOptions *request = [PHVideoRequestOptions new];
        request.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        request.version = PHVideoRequestOptionsVersionCurrent;
        request.networkAccessAllowed = YES;
        
        [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:phAsset options:request resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
            resultBlock(nil, playerItem);
        }];
    }
}

+ (void)fetchAsset:(id<AMPhotoAsset>)asset
     withImageType:(AMAssetImageType)imageType
          syncMode:(BOOL)isSynchronous
        completion:(void (^)(UIImage *))resultBlock {
    if (AMAssetMediaTypeImage != asset.mediaType) {
        if (AMAssetImageTypeFullResolution == imageType) {
            resultBlock(nil);
            return;
        }
    }
    
    PHImageRequestOptions *request = [PHImageRequestOptions new];
    request.version = PHImageRequestOptionsVersionCurrent;
    request.synchronous = isSynchronous;
    request.networkAccessAllowed = YES;
    
    CGSize targetSize = CGSizeZero;
    switch (imageType) {
        case AMAssetImageTypeThumbnail:
        {
            targetSize = AMPhotoAssetThumbnailSize;
            CGSize pixelSize = asset.dimensions;
            CGFloat pixelWidth = MIN(pixelSize.width, pixelSize.height);
            CGRect cropRect = CGRectMake((pixelSize.width - pixelWidth) * 0.5, (pixelSize.height - pixelWidth) * 0.5, pixelWidth, pixelWidth);
            request.normalizedCropRect = CGRectMake(cropRect.origin.x / pixelSize.width, cropRect.origin.y / pixelSize.height, cropRect.size.width / pixelSize.width, cropRect.size.height / pixelSize.height);
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            break;
        }
        case AMAssetImageTypeAspectRatioThumbnail:
        {
            targetSize = AMPhotoAssetThumbnailSize;
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        }
            break;
        case AMAssetImageTypeFullScreen:
        {
            CGFloat scale = [UIScreen mainScreen].scale;
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            targetSize = CGSizeMake(screenSize.width *= scale, screenSize.height *= scale);
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
            //PHImageRequestOptionsDeliveryModeHighQualityFormat: Make sure clients will get one result only
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        }
            break;
        case AMAssetImageTypeFullResolution:
        {
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            //PHImageRequestOptionsDeliveryModeHighQualityFormat: Make sure clients will get one result only
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        }
            break;
        default:
            break;
    }
    
    PHAsset *phAsset = asset.wrappedInstance;
    if (AMAssetImageTypeFullResolution != imageType) {
        [[PHCachingImageManager defaultManager] requestImageForAsset:phAsset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
            resultBlock(result);
        }];
    }
    else {
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:phAsset options:request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (nil == imageData) {
                resultBlock(nil);
            }
            else {
                resultBlock([UIImage imageWithData:imageData]);
            }
        }];
    }
}

@end
