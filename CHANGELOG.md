# MapsIndoors iOS SDK v4

### iOS Version Requirements[​](https://docs.mapsindoors.com/changelogs/ios#ios-version-requirements) <a href="#ios-version-requirements" id="ios-version-requirements"></a>

MapsIndoors iOS SDK v4 requires at least iOS 14 and Xcode 15.

### \[4.5.2\] 2024-06-11

#### Fixed

* Label styling is now respected, both on Google Maps and Mapbox, including the `labelMaxWidth` on display rules.
* Offline directions queries not working reliably.

#### Changes
* The `labelMaxWidth` display rule property is interpreted as a measure of max allowed characters per line on Mapbox - but remains a measure of max screen points per line on Google Maps.
* Added podspec dependency on MapKit - no effects for users.

### \[4.5.1\] 2024-06-06

#### Fixed

* The rendered route will now be animated when calling `MPDirectionsRenderer/render()` if `MPDirectionsRenderer/animationDuration` is different from 0. 

### \[4.5.0\] 2024-05-30

#### Added

* Support for Mapbox v11
  * Going forward, the MapsIndoors iOS SDK is distributed in both Mapbox v10 and v11 compatible versions, and the following CocoaPods may be used:
    - `pod MapsIndoorsMapbox, '~> 4.5'`
    - `pod MapsIndoorsMapbox11, '~> 4.5'`
    - `pod MapsIndoorsGoogleMaps, '~> 4.5'`
  * Minimum version of Mapbox is 11.4.0.
  * Added `setMapsIndoorsTransitionLevel(zoom: Int)` on `MPMapConfig` for users of the `MapsIndoorsMapbox11` pod.
  * No breaking changes on the MapsIndoors interface - however, the move from Mapbox v10 to v11 requires some level of code migration in your application. Refer to Mapbox's [migration documentation](https://docs.mapbox.com/ios/maps/guides/migrate-to-v11/) on the matter.

### \[4.4.1\] 2024-05-30

#### Fixed

* Improved entry point selection when routing between MapsIndoors Venues and the external world.
* Bug where the floor selector would not function as intended on buildings without a floor index 0.
* Issue where the `MPDirectionsRenderer` would not adjust the camera and selected floor, according to the currently selected route leg.
* Issue with `buildingSelectionMode` and `floorSelectionMode` properties on MapControl not being respected.

### \[4.4.0\] 2024-05-27

#### Added

* Support for Multi-stop navigation
  * `MPDirectionsQuery` now has properties `stops` and `stopsPoints`, where you may set any number of stop points, your route query should visit between the origin and destination.
  * `MPDirectionsQuery` also has a new property `optimizeRoute`, which if `true` will organize the provided stop points along the route in the most optimal order, in terms of travel time. If `false` the provided stop points will be visited in the declared order.
  * `MPDirectionsRenderer` has a new property `defaultRouteStopIcon: MPRouteStopIconProvider`, which may be overwritten with your own implementation.
  * Added `MPRouteStopIconConfig` which is a default implemenation of `MPRouteStopIconProvider`. You may reuse this, and alter some visual aspects: `MPRouteStopIconConfig(numbered: Bool, label: String?, color: UIColor)`, which can show a number within the pin indicating the stop index, or a label underneath the pin, and define the color of the pin.

### [4.3.13] 2024-05-14

#### Added
- Added Graphic Label support (Mapbox only)

#### Fixed
- Bug where icons with a badge applied (either due to display rule badging or LiveData) would cause the icon to be flipped.
- Issue with LiveData not working on certain solutions.

### [4.3.12] 2024-05-07

#### Fixed
- Issue with wrongfully calculated map viewport, when using a Mapbox view which does not occupy the entire screen space.
- Issue where the selected building could rapidly change between `nil` and the actual current building, when moving the camera.

### [4.3.11] 2024-05-03

#### Fixed
- Large memory usage on certain customer solutions with 2D models, which was introduced in 4.3.10
- The route polyline not being completely removed when calling `clear()` on the `MPDirectionsRenderer` instance, on Mapbox.

### [4.3.10] 2024-04-30

#### Added
- Added `MPCameraViewFitMode.none` option to have the camera not change position, rotation and zoom when rendering a new route.

#### Fixed
- Invalid keys in Privacy Manifest.
- When using Selective Venue Loading, too much data about buildings would be loaded. Now only the data for buildings in the selected venues is loaded.
- A number of potential crashes removed.

#### Changed
- Updated to Google Maps 8.4.0 which in turn raises the minimum required iOS version to iOS 14.

### [4.3.9] 2024-04-17

#### Added
- Ability to disable the automatic selection of Buildings and/or Floors when moving the map around. Use `MPMapControl.buildingSelectionMode` and `MPMapControl.floorSelectionMode` to control the behavior.
- Ability to toggle rendering of map features on and off. Use `MPMapControl.hiddenFeatures` to control what should be visible on your map. 
- The MapsIndoors SDK now includes a Privacy Manifest as described by Apple in [Upcoming third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements).
- Each XCFramework in the MapsIndoors SDK is now signed so you can be sure it originates from MapsPeople.

#### Fixed
- The `MPSelectionBehavior.zoomToFit` is now properly respected.
- The built-in Floor Selector would sometimes not update to show the correct floor. It does now.

#### Changed
- Rendering order of 3D Extruded Walls (only Mapbox) has changed slightly so outlines from neighboring rooms do not show through the walls. 
- Updated to Mapbox 10.17.0.

### [4.3.8] 2024-03-25

#### Fixed
- Fixed issue with `locationsWith(externalIds:)` not reliably returning locations.
- Applying User Roles would not always be respected.

#### Changed
- Changed tap behavior on rendered map features. Now only visible features are tappable, whereas before invisible geometries could be tapped.

### [4.3.7] 2024-03-21

#### Fixed
- Crash in `locationsWith(externalIds:)` removed.

### [4.3.6] 2024-03-20

#### Fixed
- Search with MPQuery now respects all properties again.
- Plugged a number of major memory leaks. 

### [4.3.5] 2024-03-07

#### Changed
- Updated to Mapbox 10.16.4
- No longer depends on MapboxDirections Cocoapod.

#### Fixed
- Significantly reduced risk of race conditions during SDK load, which would make MapsIndoors appear as not loading at all.
- An issue where polygon geometries are not clickable under certain circumstances.

### [4.3.4] 2024-03-05

Retracted due to build issues. Replaced by 4.3.5.

### [4.3.3] 2024-02-23

#### Fixed
- A Location would not be selectable if the icon is not visible.
- Label behavior on Mapbox when there is no icon, and only a label (the label will center on the anchor point).

### [4.3.2] 2024-02-14

#### Fixed
- Issue where some polygons would not render, using Google Maps.
- The `selectable` property on locations would not always be respected.

#### Added
- `locationSettings` property on `MPLocation`, `MPType` and `MPSolutionConfig`.

### [4.3.1] 2024-02-13

#### Fixed
- Extended zoom for Mapbox is now properly applied.
- Icons for some map solutions are now crisper.

#### Changed
- The compass on Mapbox is no longer hidden by the SDK, so the app will have to do that.
- Selection of locations now behaves as on Android and Web.

### [4.3.0] 2024-02-02

#### Changed
- Due to the introduction of the new `selected` display rule, there has been a behavior change in the default visualization of selected locations. The old behavior can be re-enabled by `MPMapsIndoors.shared.solution?.config.newSelection = false`. Or the new selection display rule may be retrieved and altered using `MPMapsIndoors.shared.displayRuleFor(displayRuleType: .selection)`.

#### Added
- Two new Display Rule Types: `highlight` and `selected`. With these Display Rules it is possible to define how Locations should look when selected or highlighted.
- The `highlight` Display Rule contains a number of `badge` properties that can be used to define the badge that will be shown when using this Display Rule.
- A new `MPHighlightBehavior` that determines how the result of applying a highlight should be displayed on the map.
- `setHighlight(filter:behavior:)` and `setHighlight(locations:behavior:)` to highlight Locations on the map, making use of the new `highlight` Display Rule type.
- Support for two new types of labels: Text and Flat! (only Mapbox).
- Added new `labelStyle` section to Display Rules where you can style (only Mapbox):
  - `labelType`: Label type displayed on the map, either Text or Flat
  - `labelStyleTextSize`: Controls the size of the label
  - `labelStyleTextColor`: Controls the color of the label
  - `labelStyleTextOpacity`: Controls the opacity of the label
  - `labelStyleHaloColor`: Controls the color of the halo effect around the label
  - `labelStyleHaloWidth`: Width of the halo effect around the label
  - `labelStyleHaloBlur`: Controls the blur effect of the halo effect
  - `labelStyleBearing`: Only applicable when Flat Label type is selected. Controls bearing of the Flat Label
- Selective Venue Loading. If your Solution contains many Venues it is now possible to only load a subset of Venues, using e.g. `load(apiKey:venueIds:)`, or changing the set of loaded Venues with `venuesToSync`, `addVenuesToSync(venueIds:)` and `removeVenuesToSync(venueIds:)`.
- It is now possible to programmatically override the Display Rule for floors, buildings and venues, to show them with e.g. a colored polygon.

#### Fixed
- `MPDirectionsService.routingWith(query:)` no longer returns a `nil`-route, instead throwing an error. 
- `MPMapsIndoors.shared.locationsWith(externalIds:)` no longer returns an empty result if called immediately after loading MapsIndoors.

### [4.2.14] 2024-01-31

#### Fixed
- Fixed a bug that could lead to either no route or a crash when used from Flutter or React Native.

### [4.2.13] 2023-12-19

#### Added
- `excludeWayTypes` added to `MPDirectionsQuery`. This allows for excluding certain `MPHighWay` types from a route query, to ensure the way type is not part of the returned route. This differs from `avoidWayTypes`, which discourages certain way types.

#### Fixed
- Fixed case where the blue dot could be rendered below tiles, on Mapbox.
- Fixed route start/end marker sizing.

### [4.2.12] 2023-12-07

#### Fixed
- Improved directions rendering camera behavior. The map view's safeAreaInsets are now respected when padding is applied, and camera movements are performed.

### [4.2.11] 2023-12-06

#### Changed
- Default logging level is changed to `info` from `error`. This does not produce much more logging – it only allows the iOS SDK version to be output on startup.

#### Fixed
- Fixed potential crash when (un)subscribing to Live Data topics.
- Fixed issue where details about a route using transit did not show.
- Fixed issue where some icons would be shown too large.
- `MPMapControlDelegate.didTap(coordinate:)` is now called with correct latitude and longitude for tapped point.
- The Directions Renderer no longer shows remains of the previous route leg. 

### [4.2.10] 2023-11-23

#### Fixed
- Fixed potential race condition, which could result in missing tiles until the floor index is changed.

### [4.2.9] 2023-11-22

#### Fixed
- Fixed missing or slow loading 2D models, and improved general performance and stability of 2D models usage (most notably on Google Maps).
- Fixed issue with missing or simplified route geometry.
- Fixed potential race condition that would result in a map with MapsIndoors tiles, but otherwise no MapsIndoors content showing.

### [4.2.8] 2023-11-10

#### Added
- Property `mapsIndoorsZoom` added to `MPMapControl`. This exposes the zoom level MapsIndoors is working with to resolve e.g. `zoomFrom` and `zoomTo` in Display Rules.
- Property `logLevel` added to `MPLog` to allow changing the amount of logs from MapsIndoors. The default log level has been changed from `debug` to `error` resulting in many fewer log messages from MapsIndoors.

#### Fixed
- In rare cases Google Maps would show the default red markers instead of MapsIndoors icons for Locations. This is no longer the case.

#### Changed
- When Locations with large and small areas are close together MapsIndoors now prioritizes the smaller Location when user tap the map.
- MapsIndoors XCFrameworks are now built with Xcode 15. 

### [4.2.7] 2023-10-23

#### Fixed
- Reduced the number of network calls leading to better performance in many cases.
- `MPDirectionsRenderer` now works actually fits the route according to `fitMode` on Google Maps.
- The default floor selector would sometimes miss detecting a floor change. No more of that.

### [4.2.6] 2023-10-09

#### Fixed
- Map rendering with Mapbox is no longer crashing after short usage.
- LiveData is now always active, even for visibly small areas.
- Labels and icons no longer risk being shown overlapped on a Mapbox map.
- 2D and 3D Models are now visible when extruded walls are shown.
- Routes between MapsIndoors Venues or from outside to inside a Venue can now be generated when using Mapbox.

#### Changed
- `setMapLabelFont` now has optional parameters with default values (only usable from Swift).
- Updated Mapbox version from 10.15.0 to 10.16.1.

### [4.2.5] 2023-09-22

#### Added
- Ability to render an entire floor geometry (only when data is available).
- Property `showLegLabel` to `MPDirectionsRenderer`.

#### Changed
- The building outline styling is now controlled by a display rule configurable in the CMS - the default selected building outline has therefore changed from pink-ish to blue. If you have previously made steps to programmatically modify the building outline display rule in your application, your changes are still applied and respected.

#### Fixed
- Issue where some positional LiveData updates would not be reflected, when using the convenient interface `enableLiveData(...)` on `MPMapControl`.
- Crash happening when attempting to query a route with `try await MPMapsIndoors.shared.directionsService.routingWith(...)` from Swift.
- Small UI issue where the default floor selector's scoll bar could flash.
- Issue with north aligned camera movement not always being respected.

### [4.2.4] 2023-08-31

#### Added

- Set user roles async/await with `MPMapsIndoors.shared.apply(userRoles: [MPUserRole])`

#### Fixed

- Building selection logic is now run when `MapControl` is instantiated - previously the camera would need to move to do this initially
- Positional LiveData POIs are now rendered when their LiveData provided position is inside the viewport, but their original position is outside the viewport
- Blue dot rendering issue where it would rotate with the camera
- Map padding issue with Google Maps
- The optional callback function on `enableLiveData(domain: String, listener: ((MPLiveUpdate) -> Void)?)` is now invoked when updates of the subscribed domain are received
- Potentially incorrect routing instruction strings
- Issue with Google Maps where two or more buildings may be highlighted simultaneously
- Issue with Google Maps where default marker (red pin) may be shown on POIs
- Issue with Google Maps where the `MPCameraViewFitMode` was not always respected
- Updated Mapbox version from 10.14.0 to 10.15.0

### \[4.2.2] 2023-08-09[​](https://docs.mapsindoors.com/changelogs/ios#422-2023-08-09) <a href="#422-2023-08-09" id="422-2023-08-09"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added) <a href="#added" id="added"></a>

* Routes between MapsIndoors venues now have descriptions in the currnet language.
* DisplayRules now supports unlimited zoom levels. The feature will be available in the MapsIndoors CMS soon.
* `MPSelectionBehavior` now has the `zoomToFit` property.

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed) <a href="#fixed" id="fixed"></a>

* Setting the `icon` property of a DisplayRule now works as expected.
* Fixed an issue with map items not showing immediately, only when map was moved slightly (Google Maps).
* Fixed an issue that would cause MapsIndoors tiles to disappear when moving the map (Mapbox Maps).
* The rendered route is now shown above polygons, e.g. for Locations (Google Maps).
* Fixed an issue that could cause multiple buildings to have an outline (Google Maps).
* The button at the end of a rendered route leg is now clickable.
* 2D Models will no longer be at risk of being obstructed by Location polygons (Mapbox Maps).
* Corrected rendering of Live Data Occupancy badges.

### \[4.2.1] 2023-06-29[​](https://docs.mapsindoors.com/changelogs/ios#421-2023-06-29) <a href="#421-2023-06-29" id="421-2023-06-29"></a>

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-1) <a href="#fixed-1" id="fixed-1"></a>

* Rendering related crash when using Mapbox

### \[4.2.0] 2023-06-29[​](https://docs.mapsindoors.com/changelogs/ios#420-2023-06-29) <a href="#420-2023-06-29" id="420-2023-06-29"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-1) <a href="#added-1" id="added-1"></a>

* Support for 3D models on Mapbox **(beta feature)**

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-2) <a href="#fixed-2" id="fixed-2"></a>

* Loading performance improved
* Loading bug fixed where the SDK would fail to load if any url resource returned >400 http codes
* Rendering issue with flashing polygons in Mapbox
* Rendering issue with wrong polygon ordering in Mapbox
* Building selection logic bug where it was undetermined which building in view was selected - it is now the center most building
* Improved MapsIndoors POI rendering with Google Maps
* Improved overall rendering performance with Mapbox
* Upgraded Mapbox version to 10.14.0
* Fixed missing “next leg”-behavior when tapping the end marker of a route leg
* Fixed issue with wrong rendering of badged icons, when using the default LiveData handling

### \[4.1.4] 2023-06-23[​](https://docs.mapsindoors.com/changelogs/ios#414-2023-06-23) <a href="#414-2023-06-23" id="414-2023-06-23"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-2) <a href="#added-2" id="added-2"></a>

* Support for external location data sources using `register()` has been restored.

### \[4.1.3] 2023-06-07[​](https://docs.mapsindoors.com/changelogs/ios#413-2023-06-07) <a href="#413-2023-06-07" id="413-2023-06-07"></a>

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-3) <a href="#fixed-3" id="fixed-3"></a>

* The `haloWidth` parameter of `setMapLabelFont()` now renders on Google Maps as well.
* The `polygonStrokeWidth` property of a DisplayRule is now being respected.
* The info window on Google Maps is shown at the correct position.

### \[4.1.2] 2023-06-01[​](https://docs.mapsindoors.com/changelogs/ios#412-2023-06-01) <a href="#412-2023-06-01" id="412-2023-06-01"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-3) <a href="#added-3" id="added-3"></a>

* `MPMapControlDelegate` has been enhanced to enable listening to camera movements.

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-4) <a href="#fixed-4" id="fixed-4"></a>

* The `iconSize` property of a DisplayRule is now being respected, so icons show up with the intended size.
* `MPCustomFloorSelector` has been rewired, allowing users to personalize the floor selection.
* Map padding is now available for Mapbox, allowing users to adjust the spacing around the map.
* The background color and solid color of a rendered route can now be customized.
* The halo effect on labels is now available for use, enhancing the visual appearance of labels.
* `MPMapControl.setFilter()` no longer crashes.

### \[4.1.1] 2023-05-23[​](https://docs.mapsindoors.com/changelogs/ios#411-2023-05-23) <a href="#411-2023-05-23" id="411-2023-05-23"></a>

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-5) <a href="#fixed-5" id="fixed-5"></a>

* The MapsIndoorsMapbox Cocoapod now uses the correct version of Mapbox

### \[4.1.0] 2023-05-17[​](https://docs.mapsindoors.com/changelogs/ios#410-2023-05-17) <a href="#410-2023-05-17" id="410-2023-05-17"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-4) <a href="#added-4" id="added-4"></a>

* Mapbox version now 10.13.1 which adds:
  * Extrusions of Walls and Rooms

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-6) <a href="#fixed-6" id="fixed-6"></a>

* Multi-line label cut-off
* Marker missing when selecting location
* Clustering icon size fix
* Mapbox 10.13.1 fixes some Layers glitching
* Fixed some known bugs

### \[4.0.3] 2023-04-21[​](https://docs.mapsindoors.com/changelogs/ios#403-2023-04-21) <a href="#403-2023-04-21" id="403-2023-04-21"></a>

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-5) <a href="#added-5" id="added-5"></a>

* [MPMapControl.showInfoWindowOnClickedLocation](https://app.mapsindoors.com/mapsindoors/reference/ios/v4-doc/documentation/mapsindoors/mpmapcontrol/showinfowindowonclickedlocation) to control if info windows should be shown when a Location is selected

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-7) <a href="#fixed-7" id="fixed-7"></a>

* Icons are now respecting zoom levels in Display Rules
* Labels are now respecting zoom levels in Display Rules inherited from the Location Type
* MPMapControl.hideFloorSelector now actually hides the floor selector

### \[4.0.2] 2023-04-13[​](https://docs.mapsindoors.com/changelogs/ios#402-2023-04-13) <a href="#402-2023-04-13" id="402-2023-04-13"></a>

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-8) <a href="#fixed-8" id="fixed-8"></a>

* A number of rendering issues have been corrected.
* An issue that could prevent a route from being correctly created.

### \[4.0.1] 2023-04-05[​](https://docs.mapsindoors.com/changelogs/ios#401-2023-04-05) <a href="#401-2023-04-05" id="401-2023-04-05"></a>

#### Fixed[​](https://docs.mapsindoors.com/changelogs/ios#fixed-9) <a href="#fixed-9" id="fixed-9"></a>

* Fixed crash with Mapbox when panning around the map.

### \[4.0.0] 2023-03-31[​](https://docs.mapsindoors.com/changelogs/ios#400-2023-03-31) <a href="#400-2023-03-31" id="400-2023-03-31"></a>

Version 4 of the MapsIndoors SDK has changed significantly compared to version 3. There is a [migration guide](https://docs.mapsindoors.com/getting-started/ios/v4/v4-migration-guide) that describes the changes.

#### Added[​](https://docs.mapsindoors.com/changelogs/ios#added-6) <a href="#added-6" id="added-6"></a>

* Support for new map providers
  * MapsIndoors can now be used with the Mapbox v10 SDK.
* `goTo(entity:)`
  * A new method for moving the camera to MapsIndoors locations, this new method goTo() can be used with any class that implements MPEntity, which includes but is not limited to MPLocation, MPFloor, and MPBuilding.
* Solution Config
  * The SDK now supports the Solution Config.
  * This also introduces the new Main Display Rule, which is bundled into the solution config, along with collision handling and clustering.
* New Cocoapods
  * The main Cocoapod to use is either `MapsIndoorsGoogleMaps` or `MapsIndoorsMapbox` depending on the map engine to use.
    * Both of these Cocoapods are dependent on the `MapsIndoors` and `MapsIndoorsCore` Cocoapods and will automatically include them.
    * Most classes in `MapsIndoorsCore` are public but meant for communication between the core SDK and map platform specific code. These classes are not described in the reference docs. Refrain from using these classes unless you know what you are doing.

#### Changed[​](https://docs.mapsindoors.com/changelogs/ios#changed) <a href="#changed" id="changed"></a>

* Initialisation of MapsIndoors
  * The interface to initiate the SDK is improved for smaller and safer implementations.
  * Initialise MapsIndoors with `MPMapsIndoors.shared.load(apiKey: "YOUR_MAPSINDOORS_API_KEY")`
* Initialization of MapControl
  * In order to support multiple map engines an `MPMapConfig` is needed.
  * The `MPMapConfig` is then used to create a MapControl: `let mapControl = MPMapsIndoors.createMapControl(mapConfig: mapConfig)`.
* Display Rules
  * Display Rules have been reworked completely.
  * Display Rules are now reference based, thus any changes to a rule are instantaneous.
  * Display Rules can be reset with `reset()`. This will return the display rule to the state it has in the CMS.
* The iOS SDK Reference Docs have been modernised and are now available at [https://app.mapsindoors.com/mapsindoors/reference/ios/v4-doc/documentation/mapsindoors/](https://app.mapsindoors.com/mapsindoors/reference/ios/v4-doc/documentation/mapsindoors/)
* Many interface changes. See migration guide for help in migrating from MapsIndoors SDK v3.
* Minimum iOS version supported is iOS 13.
* Required Xcode version is Xcode 14.
