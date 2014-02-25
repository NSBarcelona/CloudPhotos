//
//  BCNPhoto.m
//  CloudPhotos
//
//  Created by Hermes on 24/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "BCNPhoto.h"

@implementation BCNPhoto

@dynamic imageData;
@dynamic date;

- (UIImage*)image
{
    return [UIImage imageWithData:self.imageData];
}

@end
