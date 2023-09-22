//
//  MPDerivedGeometryCollection.h
//  MapsIndoorsCore
//
//  Created by Frederik Hansen on 20/04/2023.
//  Copyright © 2023 MapsPeople A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapsIndoors;

@class MPDerivedGeometry;

@interface MPDerivedGeometryCollection : NSObject

- (instancetype _Nonnull)initWithDerivedGeometries:(NSArray<MPDerivedGeometry*>* _Nullable)derivedGeometries;

- (NSArray<MPDerivedGeometry*>* _Nonnull) getDerivedGeometriesForLocationId:(NSString* _Nonnull)locationId;

@property (nonatomic, strong, nonnull) NSDictionary<NSString*, MPDerivedGeometry*>* floor;

@property (nonatomic, strong, nonnull) NSDictionary<NSString*, MPDerivedGeometry*>* walls;

@property (nonatomic, strong, nonnull) NSDictionary<NSString*, MPDerivedGeometry*>* extrusions;

@end
