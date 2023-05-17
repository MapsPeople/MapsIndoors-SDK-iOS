//
//  MPDerivedGeometry.h
//  MapsIndoorsCore
//
//  Created by Frederik Hansen on 19/04/2023.
//  Copyright © 2023 MapsPeople A/S. All rights reserved.
//

#import "JSONModel.h"
@import MapsIndoors;

@interface MPDerivedGeometry : JSONModel

@property (nonatomic, strong, nullable) NSString* geodataId;

@property (nonatomic, strong, nullable) NSString* geodataType;

@property (nonatomic, strong, nullable) NSString* type;

@property (nonatomic, strong, nullable) NSDictionary* geometry;

@property (nonatomic, strong, nullable) MPGeometry* mpGeometry;

@end
