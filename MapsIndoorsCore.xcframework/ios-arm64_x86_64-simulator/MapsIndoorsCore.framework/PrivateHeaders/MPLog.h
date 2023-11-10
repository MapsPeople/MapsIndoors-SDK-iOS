//
//  MPLog.h
//  MapsIndoors
//
//  Created by Daniel Nielsen on 06/10/2020.
//  Copyright © 2020 MapsPeople A/S. All rights reserved.
//

#pragma mark - [INTERNAL - DO NOT USE]

/// > Warning: [INTERNAL - DO NOT USE]
#ifndef MPLog_h
#define MPLog_h

@import MapsIndoors;

#define MPLogDebug(...) [MPLog.core debug: [NSString stringWithFormat:@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]]]
#define MPLogInfo(...) [MPLog.core info: [NSString stringWithFormat:__VA_ARGS__]]
#define MPLogNotice(...) [MPLog.core notice: [NSString stringWithFormat:__VA_ARGS__]]
#define MPLogError(...) [MPLog.core error: [NSString stringWithFormat:@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]]]
#define MPLogFault(...) [MPLog.core fault: [NSString stringWithFormat:@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]]]

#endif /* MPLog_h */
