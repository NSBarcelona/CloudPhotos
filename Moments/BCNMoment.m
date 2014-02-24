//
//  BCNMoment.m
//  Moments
//
//  Created by Hermes on 24/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "BCNMoment.h"

@implementation BCNMoment

@dynamic imageData;
@dynamic date;

- (UIImage*)image
{
    return [UIImage imageWithData:self.imageData];
}

@end
