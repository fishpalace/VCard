//
//  UIImage+Addition.h
//  VCard
//
//  Created by 海山 叶 on 12-5-20.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Addition)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

- (UIImage*)scaleImageToSize:(CGSize)newSize;

@end