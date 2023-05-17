//
//  MPDerivedGeometry.h
//  MapsIndoorsCore
//
//  Created by Frederik Hansen on 18/04/2023.
//  Copyright © 2023 MapsPeople A/S. All rights reserved.
//


#import <Foundation/Foundation.h>

@class MPDerivedGeometry;

typedef void(^mpDerivedGeometryHandlerBlockType)(NSArray<MPDerivedGeometry*>* _Nullable derivedGeometries, NSError* _Nullable error);

/// > Warning: [INTERNAL - DO NOT USE]
@protocol MPDerivedGeometryProviderDelegate <NSObject>

@required
- (void) onDerivedGeometryReady: (nonnull NSArray<MPDerivedGeometry*>*)derivedGeometries;

@end

#pragma mark - [INTERNAL - DO NOT USE]

/// > Warning: [INTERNAL - DO NOT USE]
@interface MPDerivedGeometryProvider : NSObject

@property (nonatomic, weak, nullable) id <MPDerivedGeometryProviderDelegate> delegate;

- (void)getDerivedGeometryWithCompletion: (nullable mpDerivedGeometryHandlerBlockType)completionHandler;

@end
