//
//  AMPhotoAsset.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoAsset.h"

@interface AMPhotoAsset ()
{
    ALAsset *_alAsset;
    PHAsset *_phAsset;
    
    AMPhotoAssetMediaType _mediaType;
    
    BOOL _hasGotThumbnail;
    UIImage *_thumbnailImage;
    
    BOOL _hasGotAspectRatioThumbnail;
    UIImage *_aspectRatioThumbnailImage;
    
    BOOL _hasGotFullScreenImage;
    UIImage *_fullScreenImage;
    
    BOOL _hasGotFullResolutionImage;
    UIImage *_fullResolutionImage;
    
    BOOL _hasGotMetaData;
    NSDictionary *_metaData;
    NSURL *_fileURL;
    UIImageOrientation _orientation;
    
    NSTimeInterval _duration;
}
@end

@implementation AMPhotoAsset

+ (AMPhotoAsset *)photoAssetWithALAsset:(ALAsset *)asset
{
    return [[AMPhotoAsset alloc] initWithALAsset: asset];
}

+ (AMPhotoAsset *)photoAssetWithPHAsset:(PHAsset *)asset
{
    return [[AMPhotoAsset alloc] initWithPHAsset: asset];
}

- (ALAsset *)asALAsset
{
    return _alAsset;
}

- (PHAsset *)asPHAsset
{
    return _phAsset;
}

- (AMPhotoAsset *)initWithALAsset:(ALAsset *)asset
{
    self = [super init];
    if (self) {
        _alAsset = asset;
        [self commonInit];
    }
    return self;
}

- (AMPhotoAsset *)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        _phAsset = asset;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _hasGotThumbnail = NO;
    _hasGotAspectRatioThumbnail = NO;
    _hasGotFullScreenImage = NO;
    _hasGotFullResolutionImage = NO;
    _duration = 0.f;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        switch (_phAsset.mediaType) {
            case PHAssetMediaTypeImage:
                _mediaType = AMPhotoAssetMediaTypeImage;
                break;
            case PHAssetMediaTypeVideo:
                _mediaType = AMPhotoAssetMediaTypeVideo;
                _duration = _phAsset.duration;
                break;
            case PHAssetMediaTypeAudio:
                _mediaType = AMPhotoAssetMediaTypeAudio;
                break;
            default:
                _mediaType = AMPhotoAssetMediaTypeUnknown;
                break;
        }
    }
    else {
        NSString *mediaType = [_alAsset valueForProperty:ALAssetPropertyType];
        if ([mediaType isEqualToString:ALAssetTypePhoto]) {
            _mediaType = AMPhotoAssetMediaTypeImage;
        }
        else if ([mediaType isEqualToString:ALAssetTypeVideo]) {
            _mediaType = AMPhotoAssetMediaTypeVideo;
            _duration = [[_alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
        }
        else {
            _mediaType = AMPhotoAssetMediaTypeUnknown;
        }
    }
}

- (AMPhotoAssetMediaType)mediaType
{
    return _mediaType;
}

- (CGSize)dimensions
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
    }
    else {
        return _alAsset.defaultRepresentation.dimensions;
    }
}

- (NSDictionary *)metadata
{
    if (!_hasGotMetaData) {
        _hasGotMetaData = YES;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.version = PHImageRequestOptionsVersionCurrent;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.synchronous = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                if (PHAssetMediaTypeImage == _mediaType) {
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                    _metaData = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
                    CFRelease(source);
                }
                _fileURL = info[@"PHImageFileURLKey"];
                _orientation = orientation;
            }];
        }
        else {
            _metaData = _alAsset.defaultRepresentation.metadata;
            _fileURL = [_alAsset valueForProperty: ALAssetPropertyAssetURL];
            _orientation = (UIImageOrientation)_alAsset.defaultRepresentation.orientation;
        }
    }
    return _metaData;
}

- (NSDate *)creationDate
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _phAsset.creationDate;
    }
    else {
        return [_alAsset valueForProperty: ALAssetPropertyDate];
    }
}

- (CLLocation *)location
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _phAsset.location;
    }
    else {
        return [_alAsset valueForProperty: ALAssetPropertyLocation];
    }
}

- (NSURL *)assetURL
{
    if (!_hasGotMetaData) {
        [self metadata];
    }
    return _fileURL;
}

- (UIImageOrientation)orientation
{
    if (!_hasGotMetaData) {
        [self metadata];
    }
    return _orientation;
}

- (UIImage *)thumbnail
{
    if (!_hasGotThumbnail) {
        _hasGotThumbnail = YES;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(160, 160);
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFill options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                
                CGFloat minWidth = MIN(result.size.width, result.size.height);
                CGPoint offset = CGPointMake((result.size.width - minWidth) * 0.5, (result.size.height - minWidth) * 0.5);
                CGFloat scale = thumbsize.width / (minWidth * result.scale);
                
                UIGraphicsBeginImageContextWithOptions(thumbsize, NO, 1.f);
                CGContextRef contextRef = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(contextRef, 0, thumbsize.height);
                CGContextScaleCTM(contextRef, scale, -scale);
                CGContextDrawImage(contextRef, CGRectMake(-offset.x, -offset.y, result.size.width, result.size.height), result.CGImage);
                _thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }];
        }
        else {
            _thumbnailImage = [UIImage imageWithCGImage: _alAsset.thumbnail];
        }
    }
    return _thumbnailImage;
}

- (UIImage *)aspectRatioThumbnail
{
    if (!_hasGotAspectRatioThumbnail) {
        _hasGotAspectRatioThumbnail = YES;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeFast;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGSize thumbsize = CGSizeMake(160, 160);
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:thumbsize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                _aspectRatioThumbnailImage = result;
            }];
        }
        else {
            _aspectRatioThumbnailImage = [UIImage imageWithCGImage: _alAsset.aspectRatioThumbnail];
        }
    }
    return _aspectRatioThumbnailImage;
}

- (UIImage *)fullScreenImage
{
    if (AMPhotoAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    if (!_hasGotFullScreenImage) {
        _hasGotFullScreenImage = YES;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeExact;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            CGFloat scale = [UIScreen mainScreen].scale;
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            screenSize.width *= scale;
            screenSize.height *= scale;
            [[PHImageManager defaultManager] requestImageForAsset: _phAsset targetSize:screenSize contentMode:PHImageContentModeAspectFit options:request resultHandler:^(UIImage *result, NSDictionary *info) {
                _fullScreenImage = result;
            }];
        }
        else {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            _fullScreenImage = [UIImage imageWithCGImage: defaultAssetRep.fullScreenImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
        }
    }
    return _fullScreenImage;
}

- (UIImage *)fullResolutionImage
{
    if (AMPhotoAssetMediaTypeImage != _mediaType) {
        return nil;
    }
    if (!_hasGotFullResolutionImage) {
        _hasGotFullResolutionImage = YES;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            PHImageRequestOptions *request = [PHImageRequestOptions new];
            request.resizeMode = PHImageRequestOptionsResizeModeNone;
            request.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            request.version = PHImageRequestOptionsVersionCurrent;
            request.synchronous = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:_phAsset options: request resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                _fullResolutionImage = [UIImage imageWithData: imageData];
            }];
        }
        else {
            ALAssetRepresentation *defaultAssetRep = _alAsset.defaultRepresentation;
            _fullResolutionImage = [UIImage imageWithCGImage: defaultAssetRep.fullResolutionImage scale:defaultAssetRep.scale orientation:(UIImageOrientation)defaultAssetRep.orientation];
        }
    }
    return _fullResolutionImage;
}

- (NSTimeInterval)duration
{
    return _duration;
}

@end
