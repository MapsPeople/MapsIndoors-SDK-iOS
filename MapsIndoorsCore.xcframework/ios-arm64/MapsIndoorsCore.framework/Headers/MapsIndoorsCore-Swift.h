#if 0
#elif defined(__arm64__) && __arm64__
// Generated by Apple Swift version 5.7.2 (swiftlang-5.7.2.135.5 clang-1400.0.29.51)
#ifndef MAPSINDOORSCORE_SWIFT_H
#define MAPSINDOORSCORE_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wduplicate-method-match"
#pragma clang diagnostic ignored "-Wauto-import"
#if defined(__OBJC__)
#include <Foundation/Foundation.h>
#endif
#if defined(__cplusplus)
#include <cstdint>
#include <cstddef>
#include <cstdbool>
#else
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#endif

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(ns_consumed)
# define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
#else
# define SWIFT_RELEASES_ARGUMENT
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility)
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if defined(__OBJC__)
#if !defined(IBSegueAction)
# define IBSegueAction
#endif
#endif
#if !defined(SWIFT_EXTERN)
# if defined(__cplusplus)
#  define SWIFT_EXTERN extern "C"
# else
#  define SWIFT_EXTERN extern
# endif
#endif
#if !defined(SWIFT_CALL)
# define SWIFT_CALL __attribute__((swiftcall))
#endif
#if defined(__cplusplus)
#if !defined(SWIFT_NOEXCEPT)
# define SWIFT_NOEXCEPT noexcept
#endif
#else
#if !defined(SWIFT_NOEXCEPT)
# define SWIFT_NOEXCEPT 
#endif
#endif
#if defined(__cplusplus)
#if !defined(SWIFT_CXX_INT_DEFINED)
#define SWIFT_CXX_INT_DEFINED
namespace swift {
using Int = ptrdiff_t;
using UInt = size_t;
}
#endif
#endif
#if defined(__OBJC__)
#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import CoreFoundation;
@import CoreLocation;
@import Foundation;
@import MapsIndoors;
@import ObjectiveC;
@import UIKit;
#endif

#import <MapsIndoorsCore/MapsIndoorsCore.h>

#endif
#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="MapsIndoorsCore",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

#if defined(__OBJC__)

SWIFT_CLASS("_TtC15MapsIndoorsCore15InfoWindowUtils")
@interface InfoWindowUtils : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

@class MPPoint;
@class MPGeoBounds;

@interface MPBuildingInternal (SWIFT_EXTENSION(MapsIndoorsCore))
@property (nonatomic, readonly, strong) MPPoint * _Nonnull entityPosition;
@property (nonatomic, readonly, strong) MPGeoBounds * _Nonnull entityBounds;
@property (nonatomic, readonly) BOOL entityIsPoint;
@end

@protocol MPCameraPosition;
@protocol MPProjection;

SWIFT_PROTOCOL("_TtP15MapsIndoorsCore16MPCameraOperator_")
@protocol MPCameraOperator
- (void)moveWithTarget:(CLLocationCoordinate2D)target zoom:(float)zoom;
- (void)animateWithPos:(id <MPCameraPosition> _Nonnull)pos;
- (void)animateWithBounds:(MPGeoBounds * _Nonnull)bounds;
- (void)animateWithTarget:(CLLocationCoordinate2D)target zoom:(float)zoom;
@property (nonatomic, readonly, strong) id <MPCameraPosition> _Nonnull position;
@property (nonatomic, readonly, strong) id <MPProjection> _Nonnull projection;
- (id <MPCameraPosition> _Nonnull)cameraFor:(MPGeoBounds * _Nonnull)bounds inserts:(UIEdgeInsets)inserts SWIFT_WARN_UNUSED_RESULT;
@end


SWIFT_PROTOCOL("_TtP15MapsIndoorsCore14MPCameraUpdate_")
@protocol MPCameraUpdate
- (id <MPCameraUpdate> _Nonnull)fitBounds:(MPGeoBounds * _Nonnull)bounds SWIFT_WARN_UNUSED_RESULT;
- (id <MPCameraUpdate> _Nonnull)fitBoundsWithPadding:(MPGeoBounds * _Nonnull)bounds padding:(CGFloat)padding SWIFT_WARN_UNUSED_RESULT;
- (id <MPCameraUpdate> _Nonnull)fitBoundsWithEdgeInserts:(MPGeoBounds * _Nonnull)bounds edgeInsets:(UIEdgeInsets)edgeInsets SWIFT_WARN_UNUSED_RESULT;
@end

@class NSString;
@class NSDate;

SWIFT_CLASS("_TtC15MapsIndoorsCore18MPDirectionsConfig")
@interface MPDirectionsConfig : NSObject
@property (nonatomic, copy) NSArray<NSString *> * _Nonnull avoidTypes;
@property (nonatomic, copy) NSString * _Nonnull travelMode;
@property (nonatomic, copy) NSDate * _Nullable departure;
@property (nonatomic, copy) NSDate * _Nullable arrival;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_PROTOCOL("_TtP15MapsIndoorsCore21MPRouteMarkerDelegate_")
@protocol MPRouteMarkerDelegate
- (void)onRouteMarkerClickedWithTag:(NSString * _Nonnull)tag;
@end

@protocol MPDirectionsRendererDelegate;
@class MPContextualInfoSettings;
@class UIColor;
@protocol MPRoute;
@protocol MPMapControl;

SWIFT_CLASS("_TtC15MapsIndoorsCore28MPDirectionsRendererInternal")
@interface MPDirectionsRendererInternal : NSObject <MPDirectionsRenderer, MPRouteMarkerDelegate>
@property (nonatomic, readonly) BOOL isRouteShown;
@property (nonatomic) enum MPCameraViewFitMode fitMode;
@property (nonatomic, strong) id <MPDirectionsRendererDelegate> _Nullable delegate;
@property (nonatomic, strong) MPContextualInfoSettings * _Nullable contextualInfoSettings;
@property (nonatomic) UIEdgeInsets padding;
@property (nonatomic) BOOL fitBounds;
@property (nonatomic, strong) UIColor * _Nullable pathColor;
@property (nonatomic) NSInteger routeLegIndex;
@property (nonatomic, strong) id <MPRoute> _Nullable route;
- (nonnull instancetype)initWithMapControl:(id <MPMapControl> _Nonnull)mapControl OBJC_DESIGNATED_INITIALIZER;
- (void)clear;
- (BOOL)nextLeg SWIFT_WARN_UNUSED_RESULT;
- (BOOL)previousLeg SWIFT_WARN_UNUSED_RESULT;
- (void)animateWithDuration:(NSTimeInterval)duration;
- (void)onRouteMarkerClickedWithTag:(NSString * _Nonnull)tag;
- (void)update;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end


SWIFT_PROTOCOL("_TtP15MapsIndoorsCore27MPExternalDirectionsService_")
@protocol MPExternalDirectionsService
- (void)queryWithOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination config:(MPDirectionsConfig * _Nonnull)config completionHandler:(void (^ _Nonnull)(id <MPRoute> _Nullable, NSError * _Nullable))completionHandler;
@end

@class MPDistanceMatrixResult;

SWIFT_PROTOCOL("_TtP15MapsIndoorsCore31MPExternalDistanceMatrixService_")
@protocol MPExternalDistanceMatrixService
- (void)queryWithOrigins:(NSArray<NSValue *> * _Nonnull)origins destinations:(NSArray<NSValue *> * _Nonnull)destinations config:(MPDirectionsConfig * _Nonnull)config completionHandler:(void (^ _Nonnull)(MPDistanceMatrixResult * _Nullable, NSError * _Nullable))completionHandler;
@end


@interface MPFloorInternal (SWIFT_EXTENSION(MapsIndoorsCore))
@property (nonatomic, readonly, strong) MPPoint * _Nonnull entityPosition;
@property (nonatomic, readonly, strong) MPGeoBounds * _Nonnull entityBounds;
@property (nonatomic, readonly) BOOL entityIsPoint;
@end



@interface MPLocationInternal (SWIFT_EXTENSION(MapsIndoorsCore))
@property (nonatomic, readonly, strong) MPPoint * _Nonnull entityPosition;
@property (nonatomic, readonly, strong) MPGeoBounds * _Nonnull entityBounds;
@property (nonatomic, readonly) BOOL entityIsPoint;
@end



SWIFT_PROTOCOL("_TtP15MapsIndoorsCore21MPMapProviderDelegate_")
@protocol MPMapProviderDelegate
- (void)didTapAtCoordinateDelegateWithCoordinates:(CLLocationCoordinate2D)coordinates;
- (void)didChangeCameraPositionDelegate;
- (BOOL)didTapInfoWindowWithLocationId:(NSString * _Nonnull)locationId SWIFT_WARN_UNUSED_RESULT;
- (BOOL)didTapIconDelegateWithMarkerId:(NSString * _Nonnull)markerId SWIFT_WARN_UNUSED_RESULT;
@end

@protocol MapsIndoorsShared;
@class MPMapConfig;

/// The <code>MPMapsIndoors</code> class is the main entry point to the SDK.
/// Access the shared instance to load, reload or close MapsIndoors solutions using an API key, and navigate the MapsIndoors data.
/// Create new MapControl instances to visualize the MapsIndoors data from the shared instance, in an interactive map engine (Google Maps or Mapbox).
SWIFT_CLASS("_TtC15MapsIndoorsCore13MPMapsIndoors")
@interface MPMapsIndoors : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// Shared instance for a MapsIndoors session, which can be loaded, reloded and closed, as well as reading the data for a given MapsIndoors solution (venues, buildings, locations, etc.)
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) id <MapsIndoorsShared> _Nonnull shared;)
+ (id <MapsIndoorsShared> _Nonnull)shared SWIFT_WARN_UNUSED_RESULT;
/// Instantiate a new MapControl - the control objects which is used to navigate and customize the visual representation of MapsIndoors data within a map engine (Google Maps or Mapbox).
/// If no MapsIndoors shared instance is loaded and ready, this will return nil.
+ (id <MPMapControl> _Nullable)createMapControlWithMapConfig:(MPMapConfig * _Nonnull)mapConfig SWIFT_WARN_UNUSED_RESULT;
@end


@class MPGeoRegion;

SWIFT_PROTOCOL("_TtP15MapsIndoorsCore12MPProjection_")
@protocol MPProjection
@property (nonatomic, readonly, strong) MPGeoRegion * _Nonnull visibleRegion;
- (CGPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate SWIFT_WARN_UNUSED_RESULT;
- (CLLocationCoordinate2D)coordinateForPoint:(CGPoint)point SWIFT_WARN_UNUSED_RESULT;
@end


@class MPGraphNode;

SWIFT_RESILIENT_CLASS("_TtC15MapsIndoorsCore24MPRouteNetworkEntryPoint")
@interface MPRouteNetworkEntryPoint : MPPoint
@property (nonatomic, readonly) MPBoundaryType boundaryType;
@property (nonatomic, copy) NSString * _Nullable label;
+ (MPRouteNetworkEntryPoint * _Nonnull)newWithEntryPointNode:(MPGraphNode * _Nonnull)entryPointNode SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)initWithLatitude:(double)latitude longitude:(double)longitude SWIFT_UNAVAILABLE;
- (nonnull instancetype)initWithLatitude:(double)latitude longitude:(double)longitude z:(double)z SWIFT_UNAVAILABLE;
/// <blockquote>
/// Warning: [INTERNAL - DO NOT USE]
///
/// </blockquote>
- (MPRouteNetworkEntryPoint * _Nullable)initWithDictionary:(NSDictionary * _Null_unspecified)dict error:(NSError * _Nullable * _Nullable)error SWIFT_METHOD_FAMILY(none) SWIFT_WARN_UNUSED_RESULT;
@property (nonatomic, readonly, copy) NSString * _Nonnull debugDescription;
@end


@interface MPVenueInternal (SWIFT_EXTENSION(MapsIndoorsCore))
@property (nonatomic, readonly, strong) MPPoint * _Nonnull entityPosition;
@property (nonatomic, readonly, strong) MPGeoBounds * _Nonnull entityBounds;
@property (nonatomic, readonly) BOOL entityIsPoint;
@end


SWIFT_PROTOCOL("_TtP15MapsIndoorsCore34MapControlInternalExternalServices_")
@protocol MapControlInternalExternalServices
@property (nonatomic, readonly, strong) id <MPExternalDirectionsService> _Nullable externalDirectionService;
@property (nonatomic, readonly, strong) id <MPExternalDistanceMatrixService> _Nullable externalMatrixService;
@end


SWIFT_PROTOCOL("_TtP15MapsIndoorsCore35MapsIndoorsInternalActiveMapControl_")
@protocol MapsIndoorsInternalActiveMapControl
@property (nonatomic, strong) id <MPMapControl> _Nullable activeMapControlInstance;
@end


@interface NSDate (SWIFT_EXTENSION(MapsIndoorsCore))
@property (nonatomic, readonly, copy) NSString * _Nullable mp_asHTTPDate;
@property (nonatomic, readonly, copy) NSString * _Nonnull mp_asUtcIso8601;
+ (NSDate * _Nullable)mp_fromUtcIso8601:(NSString * _Nonnull)s SWIFT_WARN_UNUSED_RESULT;
@end


SWIFT_CLASS("_TtC15MapsIndoorsCore22RouteViewModelProducer")
@interface RouteViewModelProducer : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end






#endif
#if defined(__cplusplus)
#endif
#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#pragma clang diagnostic pop
#endif

#else
#error unsupported Swift architecture
#endif
