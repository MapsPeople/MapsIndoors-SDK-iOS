//
//  MPLocationFieldInternal.h
//  MapsIndoors
//
//  Created by Daniel Nielsen on 15/12/14.
//  Copyright (c) 2014 MapsPeople A/S. All rights reserved.
//

#import "JSONModel.h"
@import MapsIndoors;

#define MPLocationFieldName @"name"
#define MPLocationFieldDescription @"description"
#define MPLocationFieldAlias @"alias"
#define MPLocationFieldPhone @"phone"
#define MPLocationFieldEmail @"email"
#define MPLocationFieldImageUrl @"imageUrl"
#define MPLocationFieldWebsite @"website"

NS_ASSUME_NONNULL_BEGIN

@interface MPLocationFieldInternal : JSONModel <MPLocationField>

@property (nonatomic, copy, readonly) NSString* type;
@property (nonatomic, copy, readonly) NSString* text;
@property (nonatomic, copy, nullable, readonly) NSString* value;

@end

NS_ASSUME_NONNULL_END
