//
//  MPMIAPI.h
//  MapsIndoors
//
//  Created by Daniel Nielsen on 15/08/16.
//  Copyright © 2015-2017 MapsPeople A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - [INTERNAL - DO NOT USE]

/// > Warning: [INTERNAL - DO NOT USE]
@interface MPMIAPI : NSObject

+ (nonnull instancetype) sharedInstance;

+ (nonnull NSString*) baseUrl;

@property (nonatomic, readwrite) BOOL                           useDevEnvironment;

@end
