//
//  MPMIAPI.h
//  MapsIndoors
//
//  Created by Daniel Nielsen on 15/08/16.
//  Copyright © 2015-2017 MapsPeople A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - [INTERNAL - DO NOT USE]

/// > Warning: [INTERNAL - DO NOT USE]
@interface MPMIAPI : NSObject

+ (instancetype) sharedInstance;

+ (NSString*) baseUrl;

@property (nonatomic, readwrite) BOOL                           useDevEnvironment;

- (NSString*) liveDataUrl:(NSString*)endpoint apiKey:(nullable NSString*)apiKey;
- (NSString*) liveDataStateUrl:(NSString*)topic;

@end

NS_ASSUME_NONNULL_END
