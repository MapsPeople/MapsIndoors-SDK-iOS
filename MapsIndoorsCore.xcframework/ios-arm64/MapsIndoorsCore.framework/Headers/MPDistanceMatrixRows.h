#import <Foundation/Foundation.h> 
#import "JSONModel.h"

#pragma mark - [INTERNAL - DO NOT USE]

@class MPDistanceMatrixElements;
@protocol MPDistanceMatrixElements;

/// > Warning: [INTERNAL - DO NOT USE]
@interface MPDistanceMatrixRows : JSONModel
	@property (nonatomic, strong, nullable) NSArray<MPDistanceMatrixElements*><MPDistanceMatrixElements>* elements;
@end
