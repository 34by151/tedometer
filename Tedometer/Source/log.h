//
//  log.h
//  Ted-O-Meter
//
//  Created by Nathan on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
// From http://stackoverflow.com/questions/969130/nslog-tips-and-tricks

//#define DEBUG

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"[DEBUG] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"[INFO] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
