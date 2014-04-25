/*
 *  Ted5000.h
 *  Ted5000
 *
 *  Created by Nathan on 10/14/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import "log.h"

// turns off tick labels, leaves "Ted-O-Meter"
#define DRAW_FOR_ICON_SCREENSHOT			0
#define DRAW_FOR_DEFAULT_PNG_SCREENSHOT		0

// Test data
#define USE_TEST_DATA                       0
#define TEST_DATA_URL                       @"http://crush.hadfieldfamily.com/ted5000/LiveDataTest.xml

// Meter sizing
#define meterGap (M_PI * 0.6)
#define radOffset (M_PI + (M_PI - meterGap)/2.0)
#define meterSpan (2.0*M_PI - meterGap)
#define touchThresholdAngle (M_PI / 10.0)
#define touchThresholdRadius 10.0
#define minRadiansPerTick (M_PI / 8.0)
#define maxRadiansPerTick (M_PI / 4.0)


// Notifications
#define kNotificationDidReachStretchLimit		@"DidReachStretchLimit"
#define kNotificationMtuCountDidChange			@"MtuCountDidChange"
#define kNotificationConnectionFailure			@"ConnectionFailure"
#define kNotificationDocumentReloadWillBegin	@"DocumentReloadWillBegin"
#define kNotificationDocumentReloadDidFinish	@"DocumentReloadDidFinish"