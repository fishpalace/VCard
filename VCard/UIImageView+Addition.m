//
//  UIImageViewAddition.m
//  PushBox
//
//  Created by Xie Hasky on 11-7-28.
//  Copyright 2011年 同济大学. All rights reserved.
//

#import "UIImageView+Addition.h"
#import "UIImageView+AFNetworking.h"

@implementation UIImageView (Addition)

- (void)loadImageFromURL:(NSString *)urlString
              completion:(void (^)(BOOL succeeded))completion
{
    
    NSURL *anImageURL = [NSURL URLWithString:urlString];
    [self setImageWithURLRequest:[NSURLRequest requestWithURL:anImageURL] placeholderImage:[UIImage imageNamed:kRLAvatarPlaceHolderBG] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (completion) {
            completion(YES);
        }
    } failure:nil];
}

@end
